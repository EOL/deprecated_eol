class Activity < LoggingModel
  has_many :activity_logs
  has_many :curator_activity_logs

  def self.find_or_create(key_sym)
    key = key_sym.to_s
    if act = Activity.find_by_name(key)
      return act
    else
      # Doing this with raw sql to override the LoggingModel's default of using INSERT DELAYED
      Activity.connection.execute(ActiveRecord::Base.sanitize_sql_array(['INSERT INTO activities (name) VALUES (?)', key]))
      return Activity.find_by_name(key)
    end
  end

  def self.method_missing(name, *args, &block)
    # TODO - this should be cached, but since we're in method_missing, that's a little tricky.
    act = self.find(:first, :conditions => ["name = ?", name.to_s])
    return super unless act
    act
  end

  # Since create is normally a reserved word, the method missing won't work for it (all the time):
  def self.create
    act = self.find_by_name('create')
  end

  # Since delete is normally a reserved word, the method missing won't work for it (all the time):
  def self.delete
    act = self.find_by_name('delete')
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
