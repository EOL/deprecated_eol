class UsersDataObject < ActiveRecord::Base
  
  validates_presence_of :user_id, :data_object_id
  validates_uniqueness_of :data_object_id

  belongs_to :user
  belongs_to :data_object
  
  #has_one :user
  #has_one :data_object
  
  

  def self.get_user_submitted_data_object_ids 
    sql="Select data_object_id From users_data_objects "
    rset = UsersDataObject.find_by_sql([sql])        
    obj_ids = Array.new
    rset.each do |post|
      obj_ids << post.data_object_id      
    end    
    return obj_ids      
  end

  def self.get_user_submitted_data_info
    sql = "Select concat(users.given_name,' ', users.family_name) user_name, users_data_objects.taxon_concept_id, users_data_objects.data_object_id
    From users_data_objects Inner Join users ON users_data_objects.user_id = users.id "
    rset = UsersDataObject.find_by_sql([sql])        
    obj_ids_info = {} #same Hash.new
    rset.each do |post|
      obj_ids_info["#{post.data_object_id}"] = "#{post.user_name} xxx #{post.taxon_concept_id}"      
    end    
    return obj_ids_info        
  end  
  
  
  
end