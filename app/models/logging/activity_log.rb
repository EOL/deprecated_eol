class ActivityLog < LoggingModel
  belongs_to :taxon_concept
  belongs_to :activity
  belongs_to :link
  belongs_to :user

  def self.log(act_symbol, options = {})
    if $LOG_USER_ACTIVITY 
      user = options[:user]
      raise "You cannot log activity without a :user option" unless user
      raise "You cannot log activity without an activity argument (first arg)" unless act_symbol
      # I'm worried these won't work if they create, since we use insert_delayed on LoggingModel models...  Ick:
      act = Activity.find_or_create(act_symbol)
      link_id = options[:link] ? Link.find_or_create(options[:link]).id : nil
      return ActivityLog.create(:activity_id => act.id, :user_id => user.id, :link_id => link_id, :value => options[:value],
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


end
