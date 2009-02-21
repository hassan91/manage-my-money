# == Schema Information
# Schema version: 20090221110740
#
# Table name: categories
#
#  id                :integer       not null, primary key
#  name              :string(255)   not null
#  description       :string(255)   
#  category_type_int :integer       
#  user_id           :integer       
#  parent_id         :integer       
#  lft               :integer       
#  rgt               :integer       
#  import_guid       :string(255)   
#  imported          :boolean       
#  type              :string(255)   
#  email             :string(255)   
#  bankinfo          :text          
#

class LoanCategory < Category
  
end
