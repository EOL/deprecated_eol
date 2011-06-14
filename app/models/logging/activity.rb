class Activity < LoggingModel

  CACHE_ALL_ROWS = true
  uses_translations

  has_many :activity_logs
  has_many :curator_activity_logs

  def self.find_or_create(key_sym)
    key = key_sym.to_s
    if act = Activity.cached_find_translated(:name, key)
      return act
    else
      # Doing this with raw sql to override the LoggingModel's default of using INSERT DELAYED
      act = Activity.create()
      TranslatedActivity.connection.execute(ActiveRecord::Base.sanitize_sql_array(['INSERT INTO translated_activities (name, activity_id, language_id) VALUES (?, ?, ?)', key, act.id, Language.english.id]))
      return Activity.cached_find_translated(:name, key)
    end
  end

  def self.method_missing(name, *args, &block)
    # TODO - this should be cached, but since we're in method_missing, that's a little tricky.
    transact = TranslatedActivity.find(:first, :conditions => ["name = ? AND language_id = ?", name.to_s,
                                  Language.english.id])
    return super unless transact
    transact.activity
  end

  # Since create is normally a reserved word, the method missing won't work for it (all the time):
  def self.create
    act = self.cached_find_translated(:name, 'create')
  end

  # Since delete is normally a reserved word, the method missing won't work for it (all the time):
  def self.delete
    act = self.cached_find_translated(:name, 'delete')
  end

  # Helper to provide consistent calculation of curator actions when using curator_activity_logs_on_data_objects
  # association
  def self.raw_curator_action_ids
        [ trusted.id,
          untrusted.id,
          show.id,
          hide.id,
          inappropriate.id,
          unreviewed.id ]
  end

end
