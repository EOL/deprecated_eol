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

end
