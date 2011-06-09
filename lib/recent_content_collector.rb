module RecentContentCollector
  def self.flickr_comments(hours = 24)
    # All comments made on Flickr images which are visible in the last N hours
    # Also disregard comments which have an associated CuratorActivityLog - those comments will be sent
    # with the flickr_curator_actions
    comment_ids = Comment.find(:all, :select => 'comments.id', :joins => "JOIN #{DataObject.full_table_name} ON (comments.parent_type='DataObject' AND comments.parent_id=data_objects.id)", :conditions => "comments.visible_at >= DATE_SUB(UTC_TIMESTAMP(), INTERVAL #{hours} HOUR) AND data_objects.source_url LIKE 'http://www.flickr.com%'")
    comments = Comment.find_all_by_id(comment_ids.collect{|c| c.id}, :include => [:parent, :user, :actions_history])

    # remove any that cannot find their Flickr image ID
    comments.each_with_index do |comment, index|
      comments[index] = nil unless comment.actions_history.nil?
      comments[index] = nil unless comment.parent.flickr_photo_id
    end
    comments.compact
  end

  def self.flickr_curator_actions(hours = 24)
    # All curator actions made on Flickr images in the last N hours
    actions_history_ids = CuratorActivityLog.find(:all, :select => 'actions_histories.id', :joins => "JOIN #{DataObject.full_table_name} ON (actions_histories.changeable_object_type_id=#{ChangeableObjectType.data_object.id} AND actions_histories.object_id=data_objects.id)", :conditions => "actions_histories.created_at >= DATE_SUB(UTC_TIMESTAMP(), INTERVAL #{hours} HOUR) AND actions_histories.action_with_object_id IN (#{ActionWithObject.trusted.id}, #{ActionWithObject.untrusted.id}, #{ActionWithObject.inappropriate.id}) AND data_objects.source_url LIKE 'http://www.flickr.com%'")
    actions_histories = CuratorActivityLog.find_all_by_id(actions_history_ids.collect{|ah| ah.id}, :include => [:user, :comment, :changeable_object_type, :action_with_object])

    # remove any that cannot find their Flickr image ID
    actions_histories.each_with_index do |actions_history, index|
      actions_histories[index] = nil unless actions_history.data_object.flickr_photo_id
    end
    actions_histories.compact
  end
end
