class ActionWithObject < ActiveRecord::Base
  CACHE_ALL_ROWS = true
  has_many :actions_histories
  
  validates_presence_of   :action_code
  validates_uniqueness_of :action_code
  
  # Helper to provide consistent calculation of curator actions when using actions_histories_on_data_objects
  # association
  def self.raw_curator_action_ids
        [ trusted.id,
          untrusted.id,
          show.id,
          hide.id,
          inappropriate.id,
          unreviewed.id ]
  end

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

