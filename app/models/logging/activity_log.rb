class ActivityLog < LoggingModel
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
      return ActivityLog.create(:activity_id => act.id, :user_id => user.id, :value => options[:value],
                                :taxon_concept_id => options[:taxon_concept_id])
    end
  end

  def self.get_activity_ids(user_id)
    if(user_id == 'all') then
      sql="Select activity_id id From activity_logs "
      rset = ActivityLog.find_by_sql([sql])
    else
      sql="Select activity_id id From activity_logs where user_id = ? "
      rset = ActivityLog.find_by_sql([sql, user_id])
    end
    obj_ids = Array.new
    rset.each do |rec|
      obj_ids << rec.id
    end
    return obj_ids
  end

  def self.user_activity(user_id, activity_id, page)
    query="Select * From activity_logs al Where 1=1 "
    if(user_id != 'All') then
      query << " AND al.user_id = ? "
    end
    if(activity_id != 'All') then
      query << " AND al.activity_id = ? "
    end
    query << " order by al.id desc "
    if    (user_id == 'All' and activity_id == 'All') then self.paginate_by_sql [query], :page => page, :per_page => 30
    elsif (user_id != 'All' and activity_id != 'All') then self.paginate_by_sql [query, user_id, activity_id], :page => page, :per_page => 30
    elsif (user_id != 'All' and activity_id == 'All') then self.paginate_by_sql [query, user_id], :page => page, :per_page => 30
    elsif (user_id == 'All' and activity_id != 'All') then self.paginate_by_sql [query, activity_id], :page => page, :per_page => 30
    end
  end

  def self.most_common_activities(page)
    query="SELECT COUNT(a.id) count, a.name, a.id FROM activities a JOIN activity_logs al ON a.id = al.activity_id GROUP BY a.name ORDER BY Count(a.id) desc"
    self.paginate_by_sql [query], :page => page, :per_page => 30
  end

  def self.most_common_combinations(activity_id)
    monitored_activity = Array.new
    sql="Select distinct al.user_id From activity_logs al"
    if(activity_id) then sql += " where al.activity_id = #{activity_id} " end
    rset = ActivityLog.find_by_sql([sql])
    rset.each do |rec|
      monitored_activity = start_user_monitoring(rec.user_id,monitored_activity)
    end

    counts = Hash.new
    monitored_activity.each do |records|
      str=""
      records.each do |rec|
        str = str + " | " + rec
      end
      counts[str] = counts[str].to_i + 1
    end
    counts = counts.sort{|a,b| b[1]<=>a[1]}
    return counts
  end

  # TODO - This is only going to work for English.  :\
  def self.start_user_monitoring(user_id,monitored_activity)
    sql="SELECT ta.name, al.created_at FROM activity_logs al JOIN activities a ON al.activity_id = a.id JOIN translated_activities ta ON (a.id = ta.activity_id AND ta.language_id = #{Language.english.id}) WHERE al.user_id = #{user_id} "
    sql += " ORDER BY al.created_at ASC"
    arr = LoggingModel.connection.execute(sql).all_hashes
    arr.each do |rec|
      next_activities = get_subsequent_activities_for_a_duration(rec['name'],rec['created_at'],arr,user_id)
      monitored_activity << next_activities
    end
    return monitored_activity
  end

private

  def self.get_subsequent_activities_for_a_duration(name,created_at,arr,user_id)
    activities = Array.new
    start_saving=false
    arr.each do |rec|
      if(name == rec['name'] and created_at == rec['created_at'])
        start_saving=true
      end
      if(start_saving) then
        end_time = get_time_after_some_minutes(created_at,5)
        if(rec['created_at'] <= end_time) then
          if(!activities.include?(rec['name']))
            activities << rec['name']
          end
        else break
        end
      end
    end
    return activities
  end

  def self.get_time_after_some_minutes(time,minutes)
    time = Time.parse(time)
    time = time + minutes*60
    #"2010-10-08 11:11:56"
    return time.strftime("%Y-%m-%d %H:%M:%S")
  end

end
