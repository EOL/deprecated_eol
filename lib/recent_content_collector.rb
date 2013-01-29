module RecentContentCollector
  def self.flickr_comments(hours = 24)
    # All comments made on Flickr images which are visible in the last N hours
    # Also disregard comments which have an associated CuratorActivityLog - those comments will be sent
    # with the flickr_curator_actions
    comment_ids = Comment.find(:all, :select => 'comments.id', :joins => "JOIN #{DataObject.full_table_name} ON (comments.parent_type='DataObject' AND comments.parent_id=data_objects.id)", :conditions => "comments.visible_at >= DATE_SUB(UTC_TIMESTAMP(), INTERVAL #{hours} HOUR) AND data_objects.source_url LIKE 'http://www.flickr.com%'")
    comments = Comment.find_all_by_id(comment_ids.collect{|c| c.id}, :include => [:parent, :user,
                                      :curator_activity_log])

    # remove any that cannot find their Flickr image ID
    comments.each_with_index do |comment, index|
      comments[index] = nil unless comment.curator_activity_log.nil?
      comments[index] = nil unless comment.parent.flickr_photo_id
    end
    comments.compact
  end

  def self.flickr_curator_actions(hours = 24)
    # All curator actions made on Flickr images in the last N hours
    curator_activity_log_ids = CuratorActivityLog.find(:all, :select => 'curator_activity_logs.id', :joins => "JOIN #{DataObject.full_table_name} ON (curator_activity_logs.changeable_object_type_id IN (#{ChangeableObjectType.data_object.id}, #{ChangeableObjectType.data_objects_hierarchy_entry.id}, #{ChangeableObjectType.curated_data_objects_hierarchy_entry.id}) AND curator_activity_logs.target_id=data_objects.id)", :conditions => "curator_activity_logs.created_at >= DATE_SUB(UTC_TIMESTAMP(), INTERVAL #{hours} HOUR) AND curator_activity_logs.activity_id IN (#{Activity.trusted.id}, #{Activity.untrusted.id}) AND data_objects.source_url LIKE 'http://www.flickr.com%'")
    curator_activity_logs = CuratorActivityLog.find_all_by_id(curator_activity_log_ids.collect{|ah| ah.id}, :include => [:user, :comment, :changeable_object_type, :activity])

    # remove any that cannot find their Flickr image ID
    curator_activity_logs.each_with_index do |curator_activity_log, index|
      curator_activity_logs[index] = nil unless curator_activity_log.data_object.flickr_photo_id
    end
    curator_activity_logs.compact
  end
end
