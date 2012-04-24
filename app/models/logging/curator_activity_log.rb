class CuratorActivityLog < LoggingModel

  include EOL::ActivityLogItem

  belongs_to :user
  belongs_to :changeable_object_type
  belongs_to :activity
  belongs_to :comment
  belongs_to :taxon_concept
  belongs_to :hierarchy_entry

  has_many :curator_activity_logs_untrust_reasons
  has_many :untrust_reasons, :through => :curator_activity_logs_untrust_reasons

  # use these associations carefully. They don't check the changeable object type, so you might try to grab a comment
  # when you should have grabbed an object and it won't fail.
  belongs_to :data_object, :foreign_key => :object_id
  belongs_to :synonym, :foreign_key => :object_id
  belongs_to :affected_comment, :foreign_key => :object_id, :class_name => Comment.to_s

  validates_presence_of :user_id, :changeable_object_type_id, :activity_id, :created_at

  after_create :log_activity_in_solr
  after_create :queue_notifications

  def self.find_all_by_data_objects_on_taxon_concept(tc)
    dato_ids = tc.all_data_objects.map {|dato| dato.id}
    return [] if dato_ids.empty?
    # TODO - This needs to add dohes, cdohes, taxon_concept_names, and synonyms.  Have fun.  :|
    CuratorActivityLog.find_by_sql("
      SELECT *
        FROM curator_activity_logs
        WHERE
          (curator_activity_logs.changeable_object_type_id = #{ChangeableObjectType.data_object.id}
            AND object_id IN (#{dato_ids.join(',')}))
    ")
  end

  # Needed for rendering links; we need to know which association to make the link to
  def link_to
    case changeable_object_type_id
      when ChangeableObjectType.comment.id:
        comment_object.parent
      when ChangeableObjectType.synonym.id:
        if synonym && synonym.hierarchy_entry
          synonym.hierarchy_entry.taxon_concept
        else
          taxon_concept # could be nil, be careful!
        end
      else
        data_object
    end
  end

  def taxon_concept_name
    case changeable_object_type_id
      when ChangeableObjectType.data_object.id:
        data_object.get_taxon_concepts.first.entry.name.string
      when ChangeableObjectType.comment.id:
        if comment_object.parent_type == 'TaxonConcept'
          comment_parent.scientific_name
        elsif comment_object.parent_type == 'DataObject'
          if comment_parent.user.nil?
            comment_parent.get_taxon_concepts.first.entry.name.string
          else
            comment_parent.taxon_concept_for_users_text.name
          end
        end
      when ChangeableObjectType.users_data_object.id:
        udo_taxon_concept.entry.italicized_name
      when ChangeableObjectType.synonym.id:
        synonym.hierarchy_entry.taxon_concept.entry.italicized_name
      else
        raise "Don't know how to get taxon name from a changeable object type of id #{changeable_object_type_id}"
    end
  end

  def taxon_concept_id
    case changeable_object_type_id
      when ChangeableObjectType.data_object.id:
        data_object.get_taxon_concepts.first.id
      when ChangeableObjectType.comment.id:
        if comment_object.parent_type == 'TaxonConcept'
          comment_parent.id
        else
          if comment_parent.user.nil?
            comment_object.taxon_concept_id
          else
            comment_parent.taxon_concept_for_users_text.id
          end
        end
      when ChangeableObjectType.synonym.id:
        begin
          synonym.hierarchy_entry.taxon_concept_id
        rescue
          puts "ERROR: [/app/models/logging/curator_activity_log.rb] Synonym #{object_id} does not have a HierarchyEntry"
        end
      when ChangeableObjectType.users_data_object.id:
        udo_taxon_concept.id
      else
        raise "Don't know how to get the taxon id from a changeable object type of id #{changeable_object_type_id}"
    end
  end

  def data_object_type
    data_object.data_type.label
  end

  def toc_label
    data_object.toc_items[0].label
  end

  def comment_object
    Comment.find(self['object_id'])
  end

  def comment_parent
    case comment_object.parent_type
      when 'TaxonConcept' then TaxonConcept.find(comment_object.parent_id)
      when 'DataObject'   then DataObject.find(comment_object.parent_id)
      else raise "Cannot comment on #{comment_object.parent_type.to_s.pluralize}"
    end
  end

  def users_data_object
    UsersDataObject.find(self['object_id'])
  end

  def udo_parent_text
    DataObject.find(users_data_object.data_object_id)
  end

  def udo_taxon_concept
    TaxonConcept.find(users_data_object.taxon_concept_id)
  end

  def log_activity_in_solr
    curation_activities = [ Activity.trusted.id, Activity.untrusted.id, Activity.unreviewed.id, Activity.show.id, Activity.hide.id ]
    loggable_activities = {
      ChangeableObjectType.data_object.id => [ Activity.show.id, Activity.trusted.id, Activity.unreviewed.id, Activity.untrusted.id,
                                               Activity.choose_exemplar.id ],
      ChangeableObjectType.synonym.id => [ Activity.add_common_name.id, Activity.remove_common_name.id,
                                           Activity.trust_common_name.id, Activity.unreview_common_name.id,
                                           Activity.untrust_common_name.id, Activity.inappropriate_common_name.id],
      ChangeableObjectType.data_objects_hierarchy_entry.id => curation_activities,
      ChangeableObjectType.curated_data_objects_hierarchy_entry.id => curation_activities + [ Activity.add_association.id,
                                                                                              Activity.remove_association.id ],
      ChangeableObjectType.users_data_object.id => curation_activities
    }
    return unless self.activity
    return unless loggable_activities[self.changeable_object_type_id]
    return unless loggable_activities[self.changeable_object_type_id].include?(self.activity_id)
    keywords = []
    keywords << self.changeable_object_type.ch_object_type.camelize if self.changeable_object_type
    keywords << self.activity.name('en') if self.activity
    base_index_hash = {
      'activity_log_unique_key' => "CuratorActivityLog_#{id}",
      'activity_log_type' => 'CuratorActivityLog',
      'activity_log_id' => self.id,
      'action_keyword' => keywords,
      'user_id' => self.user_id,
      'date_created' => self.created_at.solr_timestamp }
    EOL::Solr::ActivityLog.index_notifications(base_index_hash, notification_recipient_objects)
  end

  def queue_notifications
    Notification.queue_notifications(notification_recipient_objects, self)
  end

  def notification_recipient_objects
    return @notification_recipients if @notification_recipients
    @notification_recipients = []
    add_recipient_user_taking_action(@notification_recipients)
    add_recipient_affected_by_common_name(@notification_recipients)
    add_recipient_affected_by_object_curation(@notification_recipients)
    add_recipient_users_watching(@notification_recipients)
    add_recipient_author_of_curated_text(@notification_recipients)
    @notification_recipients
  end

  def unknown_association?
    (hierarchy_entry.nil? || hierarchy_entry.name.nil?) && (data_object.nil? || !data_object.added_by_user?)
  end

private

  def add_recipient_user_taking_action(recipients)
    # TODO: this is a new notification type - probably for ACTIVITY only
    recipients << { :user => self.user, :notification_type => :i_curated_something,
                    :frequency => NotificationFrequency.never }
  end

  def add_recipient_affected_by_common_name(recipients)
    if self.changeable_object_type_id == ChangeableObjectType.synonym.id
      unless self.taxon_concept.blank?
        recipients << self.taxon_concept
        recipients << { :ancestor_ids => self.taxon_concept.flattened_ancestor_ids }
        # TODO: Synonym log??? this can maybe go away
        # logs_affected['Synonym'] = [ self.object_id ]
        Collection.which_contain(self.taxon_concept).each do |c|
          recipients << c
        end
      end
    end
  end

  def add_recipient_affected_by_object_curation(recipients)
    if object_is_data_object?
      recipients << self.data_object
      self.data_object.curated_hierarchy_entries.each do |he|
        recipients << he.taxon_concept
        recipients << { :ancestor_ids => he.taxon_concept.flattened_ancestor_ids }
      end
      Collection.which_contain(self.data_object).each do |c|
        recipients << c
      end
    end
  end

  def add_recipient_users_watching(recipients)
    recipients.select{ |r| r.class == Collection && r.watch_collection? }.each do |collection|
      collection.users.each do |user|
        user.add_as_recipient_if_listening_to(:curation_on_my_watched_item, recipients)
      end
    end
  end
  
  def add_recipient_author_of_curated_text(recipients)
    if object_is_data_object?
      if u = self.data_object.contributing_user
        u.add_as_recipient_if_listening_to(:comment_on_my_contribution, recipients)
      end
    end
  end

  # All of these "types" are actually stored as a data_object, for reasons that escape me at the time of this
  # writing.  ...But if you care to find out why, I suggest you look at the data objects controller.
  def object_is_data_object?
    [ ChangeableObjectType.data_object.id, ChangeableObjectType.data_objects_hierarchy_entry.id,
      ChangeableObjectType.curated_data_objects_hierarchy_entry.id, ChangeableObjectType.users_data_object.id
    ].include?(self.changeable_object_type_id)
  end

end
