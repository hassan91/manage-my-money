# == Schema Information
# Schema version: 20090226180602
#
# Table name: users
#
#  id                                               :integer       not null, primary key
#  login                                            :string(40)    
#  name                                             :string(100)   default("")
#  email                                            :string(100)   
#  crypted_password                                 :string(40)    
#  salt                                             :string(40)    
#  created_at                                       :datetime      
#  updated_at                                       :datetime      
#  remember_token                                   :string(40)    
#  remember_token_expires_at                        :datetime      
#  activation_code                                  :string(40)    
#  activated_at                                     :datetime      
#  transaction_amount_limit_type_int                :integer       default(2), not null
#  transaction_amount_limit_value                   :integer       
#  include_transactions_from_subcategories          :boolean       not null
#  multi_currency_balance_calculating_algorithm_int :integer       default(0), not null
#  default_currency_id                              :integer       default(1), not null
#  invert_saldo_for_income                          :boolean       default(TRUE), not null
#

require 'digest/sha1'

class User < ActiveRecord::Base
  extend HashEnums
  
  define_enum :transaction_amount_limit_type, [:transaction_count, 
                                               :week_count,
                                               :actual_month,
                                               :actual_and_last_month
                                               ]
  define_enum :multi_currency_balance_calculating_algorithm, [:show_all_currencies,
                                                              :calculate_with_newest_exchanges,
                                                              :calculate_with_exchanges_closest_to_transaction,
                                                              :calculate_with_newest_exchanges_but,
                                                              :calculate_with_exchanges_closest_to_transaction_but
                                                              ]

  has_many :categories, :order => 'category_type_int, lft', :dependent => :delete_all do
    def people_loans
      find(:all, :conditions => [" type = 'LoanCategory' "])
    end
  end


  Category.CATEGORY_TYPES.keys.each do |category_type|
    define_method(category_type.to_s.downcase.to_sym) do
      self.categories.top.of_type(category_type).find(:first)
    end
  end


  has_many :transfers, :dependent => :destroy
  has_many :transfer_items, :through => :transfers
  has_many :currencies, :dependent => :destroy

  #TODO: To remove
  has_many :visible_currencies,
    :class_name => 'Currency',
    :finder_sql => 'SELECT c.* FROM currencies c WHERE (c.user_id = #{id} OR c.user_id IS NULL)' #THIS IS REALLY IMPORTANT TO BE SINGLE QUOTED !!

  has_many :exchanges, :dependent => :destroy

  #TODO: To remove
  has_many :visible_exchanges,
    :class_name => 'Exchange',
    :finder_sql => 'SELECT e.* FROM exchanges e WHERE (e.user_id = #{id} OR e.user_id IS NULL)' #THIS IS REALLY IMPORTANT TO BE SINGLE QUOTED !!

  has_many :goals, :through => :categories, :dependent => :destroy
  has_many :reports, :dependent => :destroy

  belongs_to :default_currency, :class_name => "Currency"


  before_create :create_top_categories
#  before_destroy :remove_all_data

  
  def create_top_categories
    [ [ "Zasoby" , :ASSET ] ,
      [ "Przychody" , :INCOME ] ,
      [ "Wydatki" , :EXPENSE ],
      [ "Zobowiązania" , :LOAN ] ,
      [ "Bilanse otwarcia", :BALANCE ] ].each do | name, type |
      self.categories << Category.new do |c|
        c.name = name
        c.category_type = type
      end
    end
  end


  def remove_all_data
    transfer_items.delete_all
    transfers.delete_all
    categories.delete_all
    exchanges.delete_all
    currencies.delete_all
  end

  validates_inclusion_of    :transaction_amount_limit_type_int, :in => User.TRANSACTION_AMOUNT_LIMIT_TYPES.values
  validates_inclusion_of    :multi_currency_balance_calculating_algorithm_int, :in => User.MULTI_CURRENCY_BALANCE_CALCULATING_ALGORITHMS.values
  validates_presence_of     :transaction_amount_limit_value, :if => :transaction_amount_limit_with_value?
  validates_numericality_of :transaction_amount_limit_value, :greater_than => 0, :if => :transaction_amount_limit_with_value? 

  #used for conditional validation of transaction_amount_limit_value
  def transaction_amount_limit_with_value?
    [:transaction_count, :week_count].include?(transaction_amount_limit_type)
  end
  
  # Autogenerated ===============================

  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  before_create :make_activation_code 

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login,
                  :email,
                  :name,
                  :password,
                  :password_confirmation,
                  :multi_currency_balance_calculating_algorithm,
                  :include_transactions_from_subcategories,
                  :transaction_amount_limit_value,
                  :transaction_amount_limit_type,
                  :default_currency_id,
                  :invert_saldo_for_income


  # Activates the user in the database.
  def activate!
    @activated = true
    self.activated_at = Time.now.utc
    self.activation_code = nil
    save(false)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find :first, :conditions => ['login = ? and activated_at IS NOT NULL', login] # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  protected
    
  def make_activation_code
    self.activation_code = self.class.make_token
  end




end
