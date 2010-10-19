class ActionWithObject < ActiveRecord::Base
  
  has_many :actions_histories
  
  validates_presence_of   :action_code
  validates_uniqueness_of :action_code
  
  def self.rate
    cached_find(:action_code, 'rate')
  end
  
  def self.create
    cached_find(:action_code, 'create')
  end
  
  def self.trusted
    cached_find(:action_code, 'trusted')
  end
  
  def self.untrusted
    cached_find(:action_code, 'untrusted')
  end
  
  def self.inappropriate
    cached_find(:action_code, 'inappropriate')
  end
end

# == Schema Info
# Schema version: 20090602162422_create_action_with_objects
#
# Table name: action_with_objects
#
# id          int(11)       not null, primary key
# action_code varchar(255)  utf8_general_ci
# created_at  datetime
# updated_at  datetime

