class ActionWithObject < ActiveRecord::Base
  CACHE_ALL_ROWS = true
  uses_translations
  has_many :actions_histories

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
    cached_find_translated(:action_code, 'rate')
  end

  def self.created
    cached_find_translated(:action_code, 'create')
  end

  def self.trusted
    cached_find_translated(:action_code, 'trusted')
  end

  def self.untrusted
    cached_find_translated(:action_code, 'untrusted')
  end

  def self.show
    cached_find_translated(:action_code, 'show')
  end

  def self.hide
    cached_find_translated(:action_code, 'hide')
  end

  def self.unreviewed
    cached_find_translated(:action_code, 'unreviewed')
  end

  def self.inappropriate
    cached_find_translated(:action_code, 'inappropriate')
  end

  def self.delete
    cached_find_translated(:action_code, 'delete')
  end

  def self.add_association
    cached_find_translated(:action_code, 'add_association')
  end

  def self.remove_association
    cached_find_translated(:action_code, 'remove_association')
  end
end
