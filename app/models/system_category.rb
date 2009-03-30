# == Schema Information
# Schema version: 20090330164910
#
# Table name: system_categories
#
#  id                :integer       not null, primary key
#  name              :string(255)   not null
#  parent_id         :integer       
#  lft               :integer       
#  rgt               :integer       
#  created_at        :datetime      
#  updated_at        :datetime      
#  description       :string(255)   
#  category_type_int :integer       
#  cached_level      :integer       
#  name_with_path    :string(255)   
#

class SystemCategory < ActiveRecord::Base
  extend HashEnums

  has_and_belongs_to_many :categories

  acts_as_nested_set

  validates_presence_of :name, :category_type

  #FIXME: Use Category.CATEGORY_TYPES !
  define_enum :category_type, Category.CATEGORY_TYPES

  default_scope :order => "category_type_int, lft"

  def name_with_indentation
    '..'*cached_level + name
  end

  def name_with_space_indentation
    '&nbsp;'*cached_level*3 + name
  end

  named_scope :of_type, lambda { |type|
    #FIXME: Use Category.CATEGORY_TYPES !
    raise "Unknown system category type: #{type}" unless Category.CATEGORY_TYPES.include?(type)
    { :conditions => {:category_type_int => Category.CATEGORY_TYPES[type] }}
  }



  def self.create_or_update(options = {})
    id = options.delete(:id)
    record = find_by_id(id) || new
    record.id = id
    record.attributes = options
    record.category_type ||= :BALANCE #we set this default type, because we must set it before save, but in the end this type will be set with root record type
    record.save!

    if block_given?
      children_array = []
      yield(children_array)
      children_array.sort!{|a,b| a.name <=> b.name}
      children_array.each do |child|
        child.move_to_child_of(record)
      end
    end

    unless record.category_type_int.nil?
      record.descendants.each do |a|
        a.category_type_int = record.category_type_int
        a.save!
      end
    end

    record
  end


  def self.find_all_by_category_type(category)
    all :conditions => {:category_type_int => category.category_type_int}
  end


  def cached_level
    read_attribute('cached_level') || level
  end

   def get_name_with_path
    path = self_and_ancestors.inject('') { |sum, cat| sum += cat.name + ':'}
    path[0,path.size-1]
  end


end
