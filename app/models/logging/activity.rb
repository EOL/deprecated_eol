class Activity < LoggingModel
  has_many :activity_logs

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
end
