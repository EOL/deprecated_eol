class ChangeableObjectType < ActiveRecord::Base
  
  has_many :actions_histories
  
  validates_presence_of   :ch_object_type
  validates_uniqueness_of :ch_object_type
  
  def self.data_object
    Rails.cache.fetch('changeable_object_type/data_object') do
      ChangeableObjectType.find_by_ch_object_type('data_object')
    end
  end
  
  def self.comment
    Rails.cache.fetch('changeable_object_type/comment') do
      ChangeableObjectType.find_by_ch_object_type('comment')
    end
  end
  
  def self.tag
    Rails.cache.fetch('changeable_object_type/tag') do
      ChangeableObjectType.find_by_ch_object_type('tag')
    end
  end
  
  def self.users_submitted_text
    Rails.cache.fetch('changeable_object_type/users_submitted_text') do
      ChangeableObjectType.find_by_ch_object_type('users_submitted_text')
    end
  end
  
end

# == Schema Info
# Schema version: 20090611220129_create_changeable_object_types
#
# Table name: changeable_object_types
#
# id              int(11)       not null, primary key
# ch_object_type	varchar(255)	utf8_general_ci
# created_at      datetime
# updated_at      datetime
