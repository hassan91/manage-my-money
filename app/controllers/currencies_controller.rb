class CurrenciesController < ApplicationController
  
  layout 'main'
  before_filter :login_required
  before_filter :find_and_set_currency, :except =>[:index, :new, :create]
  before_filter :check_perm_read, :only => [:show]
  before_filter :check_perm_write, :only => [:edit, :update, :destroy]

  def index
    @currencies = Currency.for_user(self.current_user).find(:all, :order => 'name')
    @currency = Currency.new
  end

  
  def show
    @currency = Currency.for_user(self.current_user).find(params[:id])
  end


  def new
    @currency = Currency.new
  end


  def create
    @currency = Currency.new(params[:currency].block(:user, :user_id).merge(:user => self.current_user))
    if @currency.save
      respond_to do |format|
        format.html do
          flash[:notice] = 'Utworzono nową walutę.'
          redirect_to :action => :index
        end
      end
    else
      respond_to do |format|
        format.html do
          render :action => 'new'
        end
      end
    end
  end


  def edit
  end


  def update
    if @currency.update_attributes(params[:currency])
      flash[:notice] = 'Currency was successfully updated.'
      redirect_to :action => 'show', :id => @currency
    else
      render :action => 'edit'
    end
  end


  def destroy
    @currency.destroy
    redirect_to currencies_url
  end
  
  private
  
  def find_and_set_currency
    @currency = Currency.find(params[:id])
  end
  

  def check_perm_read
    if @currency.user != nil and @currency.user.id != self.current_user.id
      flash[:notice] = 'You do not have permission to view this currency'
      @currency = nil
      redirect_to :action => :index , :controller => :currencies
    end
  end
    

  def check_perm_write
    if @currency.user == nil or @currency.user.id != self.current_user.id
      flash[:notice] = 'You do not have permission to modify this currency'
      @currency = nil
      redirect_to :action => :index , :controller => :currencies
    end
  end
end
