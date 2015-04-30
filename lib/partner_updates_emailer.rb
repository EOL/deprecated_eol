# Used to generate (daily, weekly, monthly) emails to partners and users submitting content with lists of
# comments and curator actions on their objects or pages containing their objects
module PartnerUpdatesEmailer

  def self.send_email_updates
    # checking everything in the last (email_reports_frequency_hours - 1 hour) because the script
    # will run for a few minutes and if we check at the same time each day with a strict
    # email_reports_frequency_hours we'll miss people every other day as they will have been updated
    # 23.9 hours ago, not 24 hours ago for example

    # TODO: Send email to content partner owner - what do we do if owner email is same as contact email?
    content_partner_contacts_ready = ContentPartnerContact.find(:all, :conditions => "last_report_email IS NULL OR DATE_ADD(last_report_email, INTERVAL email_reports_frequency_hours - 1 HOUR) <= UTC_TIMESTAMP()", :include => [{:content_partner => :user}])
    users_ready = User.find(:all, :joins => :users_data_objects, :conditions => "last_report_email IS NULL OR DATE_ADD(last_report_email, INTERVAL email_reports_frequency_hours - 1 HOUR) <= UTC_TIMESTAMP()", :group => 'users.id', :readonly => false)

    content_partner_contact_frequencies = content_partner_contacts_ready.collect{|c| c.email_reports_frequency_hours}
    user_frequencies = users_ready.collect{|c| c.email_reports_frequency_hours}

    all_frequencies = content_partner_contact_frequencies | user_frequencies

    for frequency_hours in all_frequencies
      next if frequency_hours == 0
      all_activity = self.all_activity_since_hour(frequency_hours)
      self.send_emails_to_partners(all_activity[:partner_activity], content_partner_contacts_ready, frequency_hours)
      self.send_emails_to_users(all_activity[:user_activity], users_ready, frequency_hours)
    end
  end

  def self.send_emails_to_partners(partner_activity, content_partner_contacts, frequency_hours)
    partner_activity.each do |partner_id, activity|
      contacts_for_this_partner = content_partner_contacts.select{|cpc| !cpc.content_partner.nil? && cpc.email_reports_frequency_hours == frequency_hours && cpc.content_partner.id == partner_id}
      for contact in contacts_for_this_partner
        Notifier.activity_on_content_partner_content(contact.content_partner, contact, activity).deliver
        contact.last_report_email = Time.now
        contact.save!
      end
    end
  end

  def self.send_emails_to_users(user_activity, users, frequency_hours)
    user_activity.each do |user_id, activity|
      user_to_update = users.select{|u| u.email_reports_frequency_hours == frequency_hours && u.id == user_id}
      for user in user_to_update
        Notifier.activity_on_user_content(user, activity).deliver
        user.last_report_email = Time.now
        user.save!
      end
    end
  end


  def self.all_activity_since_hour(number_of_hours = 24)
    actions = self.all_actions_since_hour(number_of_hours)
    comments = self.all_comments_since_hour(number_of_hours)

    partner_activity = {}
    actions[:partner_actions].each do |id, a|
      partner_activity[id] ||= { :actions => [], :object_comments => [], :page_comments => [] }
      partner_activity[id][:actions] = a
    end
    comments[:partner_comments][:objects].each do |id, c|
      partner_activity[id] ||= { :actions => [], :object_comments => [], :page_comments => [] }
      partner_activity[id][:object_comments] = c
    end
    comments[:partner_comments][:pages].each do |id, c|
      partner_activity[id] ||= { :actions => [], :object_comments => [], :page_comments => [] }
      partner_activity[id][:page_comments] = c
    end

    user_activity = {}
    actions[:user_actions].each do |id, a|
      user_activity[id] ||= { :actions => [], :object_comments => [], :page_comments => [] }
      user_activity[id][:actions] = a
    end
    comments[:user_comments][:objects].each do |id, c|
      user_activity[id] ||= { :actions => [], :object_comments => [], :page_comments => [] }
      user_activity[id][:object_comments] = c
    end
    comments[:user_comments][:pages].each do |id, c|
      user_activity[id] ||= { :actions => [], :object_comments => [], :page_comments => [] }
      user_activity[id][:page_comments] = c
    end

    return { :partner_activity => partner_activity, :user_activity => user_activity }
  end

  def self.all_actions_since_hour(number_of_hours = 24)
    all_action_ids = ActiveRecord::Base.connection.select_values("
      SELECT id
      FROM #{CuratorActivityLog.full_table_name}
      WHERE DATE_ADD(created_at, INTERVAL #{number_of_hours} HOUR) >= UTC_TIMESTAMP()
      AND activity_id IN (#{Activity.trusted.id},#{Activity.untrusted.id},#{Activity.inappropriate.id})")

    partner_actions = {}
    user_actions = {}

    unless all_action_ids.empty?
      # Curator Actions on objects submitted by Content Partners
      result = CuratorActivityLog.find_by_sql("
        SELECT cal.*, u.username curator_username, cp.id content_partner_id
        FROM #{CuratorActivityLog.full_table_name} cal
        JOIN #{User.full_table_name} u ON (cal.user_id=u.id)
        LEFT JOIN (
          #{DataObject.full_table_name} do
          JOIN #{DataObjectsHierarchyEntry.full_table_name} dohe ON (do.id=dohe.data_object_id)
          JOIN #{HierarchyEntry.full_table_name} he ON (dohe.hierarchy_entry_id = he.id)
          JOIN #{Resource.full_table_name} r ON (he.hierarchy_id = r.hierarchy_id)
          JOIN #{ContentPartner.full_table_name} cp ON (r.content_partner_id = cp.id)
        ) ON (cal.target_id=dohe.data_object_id)
        WHERE cal.id IN (#{all_action_ids.join(',')})
        AND cal.changeable_object_type_id IN (#{ChangeableObjectType.data_object.id},#{ChangeableObjectType.data_objects_hierarchy_entry.id},#{ChangeableObjectType.curated_data_objects_hierarchy_entry.id})
        AND cp.id IS NOT NULL
        GROUP BY cp.id, cal.id")
      result.each do |r|
        partner_id = r['content_partner_id'].to_i
        partner_actions[partner_id] ||= []
        partner_actions[partner_id] << r
      end

      # Curator Actions on text submitted by Users
      result = CuratorActivityLog.find_by_sql("
        SELECT cal.*, u.username curator_username, u.id user_id FROM #{CuratorActivityLog.full_table_name} cal
        JOIN #{User.full_table_name} uc ON (cal.user_id=uc.id)
        LEFT JOIN (
          #{DataObject.full_table_name} do
          JOIN #{UsersDataObject.full_table_name} udo ON (do.id=udo.data_object_id)
          JOIN #{User.full_table_name} u ON (udo.user_id = u.id)
        ) ON (cal.target_id=udo.data_object_id)
        WHERE cal.id IN (#{all_action_ids.join(',')})
        AND cal.changeable_object_type_id  IN (#{ChangeableObjectType.users_data_object.id},#{ChangeableObjectType.data_object.id},#{ChangeableObjectType.data_objects_hierarchy_entry.id},#{ChangeableObjectType.curated_data_objects_hierarchy_entry.id})
        AND u.id IS NOT NULL
        GROUP BY u.id, cal.id")
      result.each do |r|
        user_id = r['user_id'].to_i
        user_actions[user_id] ||= []
        user_actions[user_id] << r
      end
    end

    return { :partner_actions => partner_actions, :user_actions => user_actions }
  end

  def self.all_comments_since_hour(number_of_hours = 24)
    all_comment_ids = ActiveRecord::Base.connection.select_values("SELECT id FROM #{Comment.full_table_name} WHERE DATE_ADD(created_at, INTERVAL #{number_of_hours} HOUR) >= UTC_TIMESTAMP()")

    partner_comments = { :objects => {}, :pages => {} }
    user_comments = { :objects => {}, :pages => {} }

    unless all_comment_ids.empty?
      # Comments left on objects submitted by Content Partners
      result = Comment.find_by_sql("
        SELECT c.*, u.username commenter_username, cp.id content_partner_id FROM #{Comment.full_table_name} c
        JOIN #{User.full_table_name} u ON (c.user_id=u.id)
        LEFT JOIN (
          #{DataObjectsHierarchyEntry.full_table_name} dohe
          JOIN #{HierarchyEntry.full_table_name} he ON (dohe.hierarchy_entry_id = he.id)
          JOIN #{Resource.full_table_name} r ON (he.hierarchy_id = r.hierarchy_id)
          JOIN #{ContentPartner.full_table_name} cp ON (r.content_partner_id = cp.id)
        ) ON (c.parent_id=dohe.data_object_id)
        WHERE c.id IN (#{all_comment_ids.join(',')})
        AND u.username != 'potsonna'
        AND c.parent_type = 'DataObject'
        AND cp.id IS NOT NULL
        GROUP BY cp.id, c.id")
      result.each do |r|
        partner_id = r['content_partner_id'].to_i
        partner_comments[:objects][partner_id] ||= []
        partner_comments[:objects][partner_id] << r
      end

      # Comments left on pages with objects submitted by Content Partners
      result = Comment.find_by_sql("
        SELECT c.*, u.username commenter_username, cp.id content_partner_id FROM #{Comment.full_table_name} c
        JOIN #{User.full_table_name} u ON (c.user_id=u.id)
        LEFT JOIN (
          #{HierarchyEntry.full_table_name} he
          JOIN #{Resource.full_table_name} r ON (he.hierarchy_id = r.hierarchy_id)
          JOIN #{ContentPartner.full_table_name} cp ON (r.content_partner_id = cp.id)
        ) ON (c.parent_id=he.taxon_concept_id)
        WHERE c.id IN (#{all_comment_ids.join(',')})
        AND u.username != 'potsonna'
        AND c.parent_type = 'TaxonConcept'
        AND cp.id IS NOT NULL
        GROUP BY cp.id, c.id")
      result.each do |r|
        partner_id = r['content_partner_id'].to_i
        partner_comments[:pages][partner_id] ||= []
        partner_comments[:pages][partner_id] << r
      end



      # Comments left on text submitted by Users
      result = Comment.find_by_sql("
        SELECT c.*, uc.username commenter_username, u.id receiving_user_id FROM #{Comment.full_table_name} c
        JOIN #{User.full_table_name} uc ON (c.user_id=uc.id)
        LEFT JOIN (
          #{UsersDataObject.full_table_name} udo
          JOIN #{User.full_table_name} u ON (udo.user_id = u.id)
        ) ON (c.parent_id=udo.data_object_id)
        WHERE c.id IN (#{all_comment_ids.join(',')})
        AND uc.username != 'potsonna'
        AND c.parent_type = 'DataObject'
        AND u.id IS NOT NULL
        GROUP BY u.id, c.id")
      result.each do |r|
        user_id = r['receiving_user_id'].to_i
        user_comments[:objects][user_id] ||= []
        user_comments[:objects][user_id] << r
      end

      # Comments left on pages with text submitted by Users
      result = Comment.find_by_sql("
        SELECT c.*, uc.username commenter_username, u.id receiving_user_id FROM #{Comment.full_table_name} c
        JOIN #{User.full_table_name} uc ON (c.user_id=uc.id)
        LEFT JOIN (
          #{UsersDataObject.full_table_name} udo
          JOIN #{User.full_table_name} u ON (udo.user_id = u.id)
        ) ON (c.parent_id=udo.taxon_concept_id)
        WHERE c.id IN (#{all_comment_ids.join(',')})
        AND uc.username != 'potsonna'
        AND c.parent_type = 'TaxonConcept'
        AND u.id IS NOT NULL
        GROUP BY u.id, c.id")
      result.each do |r|
        user_id = r['receiving_user_id'].to_i
        user_comments[:pages][user_id] ||= []
        user_comments[:pages][user_id] << r
      end
    end

    return { :partner_comments => partner_comments, :user_comments => user_comments }
  end
end