class UserActivityLog < LazyLoggingModel
  establish_connection("#{Rails.env}_logging")
  belongs_to :taxon_concept
  belongs_to :activity
  belongs_to :user

  def self.log(act_symbol, options = {})
    if $LOG_USER_ACTIVITY
      user = options[:user]
      raise "You cannot log activity without a :user option" unless user
      raise "You cannot log activity without an activity argument (first arg)" unless act_symbol
      # I'm worried these won't work if they create, since we use insert_delayed on LoggingModel models...  Ick:
      act = Activity.find_or_create(act_symbol)
      return UserActivityLog.create(:activity_id => act.id, :user_id => user.id, :value => options[:value],
                                :taxon_concept_id => options[:taxon_concept_id])
    end
  end

  def self.get_activity_ids(user_id)
    if(user_id == 'all') then
      sql="Select activity_id id From user_activity_logs "
      record_set = UserActivityLog.find_by_sql([sql])
    else
      sql="Select activity_id id From user_activity_logs where user_id = ? "
      record_set = UserActivityLog.find_by_sql([sql, user_id])
    end
    obj_ids = Array.new
    record_set.each do |record|
      obj_ids << record.id
    end
    return obj_ids
  end

  def self.user_activity(user_id, activity_id, page)
    query="SELECT * FROM user_activity_logs al WHERE 1=1 "
    if(user_id != 'All') then
      query << " AND al.user_id = ? "
    end
    if(activity_id != 'All') then
      query << " AND al.activity_id = ? "
    end
    query << " ORDER BY al.id DESC "
    if    (user_id == 'All' and activity_id == 'All') then self.paginate_by_sql [query], :page => page, :per_page => 30
    elsif (user_id != 'All' and activity_id != 'All') then self.paginate_by_sql [query, user_id, activity_id], :page => page, :per_page => 30
    elsif (user_id != 'All' and activity_id == 'All') then self.paginate_by_sql [query, user_id], :page => page, :per_page => 30
    elsif (user_id == 'All' and activity_id != 'All') then self.paginate_by_sql [query, activity_id], :page => page, :per_page => 30
    end
  end

  def self.most_common_activities(page)
    query="SELECT COUNT(a.activity_id) count, a.name, a.activity_id id
    FROM translated_activities a 
    JOIN user_activity_logs al ON a.activity_id = al.activity_id 
    GROUP BY a.name ORDER BY Count(a.activity_id) desc"
    self.paginate_by_sql [query], :page => page, :per_page => 30
  end

  def self.most_common_combinations(activity_id)
    monitored_activity = Array.new
    sql="SELECT DISTINCT al.user_id FROM user_activity_logs al"
    if(activity_id) then sql += " WHERE al.activity_id = #{activity_id} " end
    record_set = UserActivityLog.find_by_sql([sql])
    record_set.each do |record|
      monitored_activity = start_user_monitoring(record.user_id, monitored_activity)
    end

    counts = Hash.new
    monitored_activity.each do |records|
      str=""
      records.each do |record|
        str = str + " | " + record
      end
      counts[str] = counts[str].to_i + 1
    end
    counts = counts.sort{|a,b| b[1]<=>a[1]}
    return counts
  end

  # TODO - This is only going to work for English.  :\
  def self.start_user_monitoring(user_id, monitored_activity)
    sql = "
      SELECT ta.name, al.created_at
      FROM user_activity_logs al
      JOIN activities a ON al.activity_id = a.id
      JOIN translated_activities ta ON (a.id = ta.activity_id AND ta.language_id = #{Language.english.id})
      WHERE al.user_id = #{user_id}
      ORDER BY al.created_at ASC"
    arr = LoggingModel.connection.execute(sql)
    arr.each do |record|
      next_activities = get_subsequent_activities_for_a_duration(record[0], record[1], arr, user_id)
      monitored_activity << next_activities
    end
    return monitored_activity
  end

private

  def self.get_subsequent_activities_for_a_duration(name, created_at, arr, user_id)
    activities = Array.new
    start_saving = false
    arr.each do |record|
      if(name == record[0] and created_at == record[1])
        start_saving = true
      end
      if(start_saving) then
        end_time = get_time_after_some_minutes(created_at.to_s, 5)
        if(record[1] <= end_time) then
          if(!activities.include?(record[0]))
            activities << record[0]
          end
        else break
        end
      end
    end
    return activities
  end

  def self.get_time_after_some_minutes(time, minutes)
    time = Time.parse(time)
    time = time + minutes*60
    #"2010-10-08 11:11:56"
    return time.strftime("%Y-%m-%d %H:%M:%S")
  end

end
