class ActionWithObject < ActiveRecord::Base
  
  has_many :actions_histories
  
  validates_presence_of   :action_code
  validates_uniqueness_of :action_code
  
  def self.rate
    cached_find(:action_code, 'rate')
  end
  
  def self.created
    cached_find(:action_code, 'create')
  end
  
  def self.trusted
    cached_find(:action_code, 'trusted')
  end
  
  def self.untrusted
    cached_find(:action_code, 'untrusted')
  end
  
  def self.unreviewed
    cached_find(:action_code, 'unreviewed')
  end
  
  def self.inappropriate
    cached_find(:action_code, 'inappropriate')
  end
  
  def self.delete
    cached_find(:action_code, 'delete')
  end
end

