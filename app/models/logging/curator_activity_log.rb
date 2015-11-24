require 'eol/activity_log_item'

class CuratorActivityLog < LoggingModel
  establish_connection("#{Rails.env}_logging")

  include EOL::ActivityLogItem

  belongs_to :user
  belongs_to :changeable_object_type
  belongs_to :activity
  belongs_to :comment
  belongs_to :taxon_concept
  belongs_to :hierarchy_entry

  has_many :curator_activity_logs_untrust_reasons
  has_many :untrust_reasons, through: :curator_activity_logs_untrust_reasons

  # use these associations carefully. They don't check the changeable object type, so you might try to grab a comment
  # when you should have grabbed a target and it won't fail.
  belongs_to :data_object, foreign_key: :target_id
  belongs_to :synonym, foreign_key: :target_id
  belongs_to :classification_curation, foreign_key: :target_id
  belongs_to :affected_comment, foreign_key: :target_id, class_name: Comment.to_s
  belongs_to :data_point_uri, foreign_key: :target_id
  belongs_to :user_added_data, foreign_key: :target_id
  belongs_to :resource, foreign_key: :target_id

  validates_presence_of :user_id, :changeable_object_type_id, :activity_id

  before_save :fix_taxon_concept
  after_create :log_activity_in_solr
  after_create :queue_notifications

  # I don't know why attribute-whitelisting still applies during tests, but they do.  Grr:
  attr_accessible :user, :user_id, :changeable_object_type, :changeable_object_type_id, :target, :target_id,
    :hierarchy_entry, :hierarchy_entry_id, :taxon_concept, :taxon_concept_id, :activity, :activity_id,
    :data_object, :data_object_id, :data_object_guid, :created_at

  def self.log_preferred_classification(classification, options = {})
    CuratorActivityLog.create(
      user: options[:user],
      changeable_object_type: ChangeableObjectType.curated_taxon_concept_preferred_entry,
      target_id: classification.id,
      hierarchy_entry_id: classification.hierarchy_entry_id,
      taxon_concept_id: classification.taxon_concept_id,
      activity: Activity.preferred_classification
    )
  end

  # TODO - Association (as noted elsewhere) needs to be a class, which will
  # change this (and clean it up): clearly it should have a target attribute, a
  # changeable_object_type attribute, and a hierarchy_entry. ...Also an optional
  # taxon_concept.
  #
  # You should be passing in :action, :association, :data_object, and :user as
  # it stands now, though.
  def self.factory(options)
    return unless options[:association]
    target_id = options[:association].data_object_id if
      options[:association].is_a?(DataObjectsHierarchyEntry) ||
      options[:association].is_a?(CuratedDataObjectsHierarchyEntry) ||
      options[:association].is_a?(UsersDataObject)
    target_id ||= options[:association].id

    he =
      if options[:association].is_a?(DataObjectsHierarchyEntry) ||
         options[:association].is_a?(CuratedDataObjectsHierarchyEntry)
        options[:association].hierarchy_entry
      elsif options[:association].is_a?(HierarchyEntry)
        options[:association]
      else # UsersDataObject, notably...
        nil
      end

    changeable_object_type =
      if options[:action] == :add_association ||
         options[:action] == :remove_association
        ChangeableObjectType.curated_data_objects_hierarchy_entry
      else
        ChangeableObjectType.send(
          options[:association].class.name.underscore.to_sym
        )
      end

    create_options = {
      user_id: options[:user].id,
      changeable_object_type: changeable_object_type,
      target_id: target_id,
      activity: Activity.send(options[:action]),
      data_object_guid: options[:data_object].guid,
      hierarchy_entry: he,
      taxon_concept: he.try(:taxon_concept)
    }
    CuratorActivityLog.create(create_options)
  end

  def is_for_type?(changeable_object_type_label)
    if looked_up_type = ChangeableObjectType.send(changeable_object_type_label.to_sym)
      return true if changeable_object_type_id == looked_up_type.id
    else
      raise "Don't know how to check for changeable object type of `#{changeable_object_type_label}`"
    end
    false
  end

  # Needed for rendering "reply" links; we need to know which association to make the link to
  def link_to
    case changeable_object_type_id
      when ChangeableObjectType.comment.id
        comment_object.parent
      when ChangeableObjectType.synonym.id
        if synonym && synonym.hierarchy_entry
          synonym.hierarchy_entry.taxon_concept
        else
          taxon_concept # could be nil, be careful!
        end
      when ChangeableObjectType.taxon_concept.id
        taxon_concept
      when ChangeableObjectType.classification_curation.id
        taxon_concept
      when ChangeableObjectType.curated_taxon_concept_preferred_entry.id
        taxon_concept
      when ChangeableObjectType.data_point_uri.id
        data_point_uri
      when ChangeableObjectType.user_added_data.id
        user_added_data.data_point_uri
      when ChangeableObjectType.resource_validation.id
        resource
      else
        data_object
    end
  end

  def taxon_concept_name
    case changeable_object_type_id
      when ChangeableObjectType.data_object.id
        data_object.get_taxon_concepts.first.entry.name.string
      when ChangeableObjectType.comment.id
        if comment_object.parent_type == 'TaxonConcept'
          comment_parent.title
        elsif comment_object.parent_type == 'DataObject'
          if comment_parent.user.nil?
            comment_parent.get_taxon_concepts.first.entry.name.string
          else
            comment_parent.taxon_concept_for_users_text.name
          end
        end
      when ChangeableObjectType.users_data_object.id
        udo_taxon_concept.entry.italicized_name
      when ChangeableObjectType.classification_curation.id
        taxon_concept.entry.italicized_name
      when ChangeableObjectType.synonym.id
        synonym.hierarchy_entry.taxon_concept.entry.italicized_name
      else
        raise "Don't know how to get taxon name from a changeable object type of id #{changeable_object_type_id}"
    end
  end

  # NOTE: this is an old and (frankly) stupid workaround for not adding the
  # taxon_concept_id to the database when building the CAL. I'm keeping it here
  # until we'er confident that we're building it correctly, but if you're
  # reading this and aren't aware of the problem, it's probably okay to delete
  # this method by now. Probably.
  def deduce_taxon_concept_id
    case changeable_object_type_id
      when ChangeableObjectType.data_object.id
        hierarchy_entry.try(:taxon_concept_id)
      when ChangeableObjectType.comment.id
        if comment_object.parent_type == 'TaxonConcept'
          comment_parent.id
        else
          if comment_parent.user.nil?
            comment_object.taxon_concept_id
          else
            comment_parent.taxon_concept_for_users_text.id
          end
        end
      when ChangeableObjectType.synonym.id
        synonym.hierarchy_entry.try(:taxon_concept_id)
      when ChangeableObjectType.users_data_object.id
        udo_taxon_concept.id
      when ChangeableObjectType.taxon_concept.id
        taxon_concept.id
      when ChangeableObjectType.curated_taxon_concept_preferred_entry.id
        taxon_concept.id
      when ChangeableObjectType.classification_curation.id
        taxon_concept.id
      when ChangeableObjectType.data_point_uri.id
        taxon_concept.id
      when ChangeableObjectType.user_added_data.id
        taxon_concept.id
      when ChangeableObjectType.data_objects_hierarchy_entry.id
        hierarchy_entry.try(:taxon_concept_id)
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
    Comment.find(self['target_id']) # TODO ...why the archaeic syntax?
  end

  def comment_parent
    case comment_object.parent_type
      when 'TaxonConcept' then TaxonConcept.find(comment_object.parent_id)
      when 'DataObject'   then DataObject.find(comment_object.parent_id)
      else raise "Cannot comment on #{comment_object.parent_type.to_s.pluralize}"
    end
  end

  def data_point_uri
    DataPointUri.find(target_id) if changeable_object_type == ChangeableObjectType.data_point_uri
  end

  def users_data_object
    data_object.users_data_object
  end

  def udo_parent_text
    DataObject.find(users_data_object.data_object_id) rescue nil
  end

  def udo_taxon_concept
    TaxonConcept.find(users_data_object.taxon_concept_id) rescue nil
  end

  def log_activity_in_solr
    curation_activities = [ Activity.trusted.id, Activity.untrusted.id, Activity.unreviewed.id,
      Activity.show.id, Activity.hide.id ]
    loggable_activities = {
      ChangeableObjectType.data_object.id => [ Activity.show.id, Activity.trusted.id, Activity.unreviewed.id,
                                               Activity.untrusted.id, Activity.choose_exemplar_image.id,
                                               Activity.choose_exemplar_article.id, Activity.crop.id ],
      ChangeableObjectType.synonym.id => [ Activity.add_common_name.id, Activity.remove_common_name.id,
                                           Activity.trust_common_name.id, Activity.unreview_common_name.id,
                                           Activity.untrust_common_name.id, Activity.inappropriate_common_name.id],
      ChangeableObjectType.data_objects_hierarchy_entry.id => curation_activities,
      ChangeableObjectType.curated_data_objects_hierarchy_entry.id => curation_activities +
        [ Activity.add_association.id, Activity.remove_association.id ],
      ChangeableObjectType.users_data_object.id => curation_activities,
      ChangeableObjectType.curated_taxon_concept_preferred_entry.id => [Activity.preferred_classification.id],
      ChangeableObjectType.classification_curation.id => [Activity.unlock.id,
                                                          Activity.unlock_with_error.id,
                                                          Activity.curate_classifications.id],
      ChangeableObjectType.taxon_concept.id => [Activity.split_classifications.id, Activity.merge_classifications.id],
      ChangeableObjectType.data_point_uri.id => [Activity.set_exemplar_data.id, Activity.hide.id, Activity.unhide.id],
      ChangeableObjectType.user_added_data.id => [Activity.create.id, Activity.update.id]
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
    LoggingModel.clear_taxon_activity_log_fragment_caches(notification_recipient_objects)
  end

  def queue_notifications
    Notification.queue_notifications(notification_recipient_objects, self)
  end

  def notification_recipient_objects
    return @notification_recipients if @notification_recipients
    @notification_recipients = []
    add_recipient_user_taking_action(@notification_recipients)
    add_recipient_taxon_concepts(@notification_recipients)
    add_recipient_affected_by_object_curation(@notification_recipients)
    add_recipient_users_watching(@notification_recipients)
    add_recipient_author_of_curated_text(@notification_recipients)
    @notification_recipients
  end

  def unknown_association?
    (hierarchy_entry.nil? || hierarchy_entry.name.nil?) && (data_object.nil? || !data_object.added_by_user?)
  end

private

  def fix_taxon_concept
    unless self[:taxon_concept_id] || self.taxon_concept
      self[:taxon_concept_id] = find_missing_taxon_concept_id
    end
  end

  def find_missing_taxon_concept_id
    # NOTE: Using #find_by_id below to avoid exceptions!
    if changeable_object_type == ChangeableObjectType.comment
      comment = Comment.find_by_id(target_id)
      return
        if comment.nil?
          nil
        elsif comment.parent_type == 'TaxonConcept'
          comment.parent.id
        else
          comment.taxon_concept_id ||
            comment.parent.try(:taxon_concept_for_users_text).try(:id)
        end
    end
    if changeable_object_type == ChangeableObjectType.synonym
      return Synonym.find_by_id(target_id).try(:hierarchy_entry).try(:taxon_concept_id)
    end
    if changeable_object_type == ChangeableObjectType.users_data_object
      return UsersDataObject.find_by_id(target_id).try(:taxon_concept_id)
    end
  end

  def add_recipient_user_taking_action(recipients)
    # TODO: this is a new notification type - probably for ACTIVITY only
    recipients << { user: self.user, notification_type: :i_curated_something,
                    frequency: NotificationFrequency.never }
  end

  # There are a few types of CuratorActivityLogs that only notify their taxon concepts:
  def add_recipient_taxon_concepts(recipients)
    if self.is_for_type?(:synonym) ||
       self.is_for_type?(:curated_taxon_concept_preferred_entry) ||
       self.is_for_type?(:taxon_concept)
      add_taxon_concept_recipients(self.taxon_concept, recipients)
      add_taxon_concept_recipients(TaxonConcept.find(self.target_id), recipients) if
        self.is_for_type?(:taxon_concept)
    end
    if self.is_for_type?(:classification_curation) &&
       self.activity_id == Activity.curate_classifications.id &&
       cc = self.classification_curation
      add_taxon_concept_recipients(cc.moved_from, recipients) if cc.moved_from
      add_taxon_concept_recipients(cc.moved_to, recipients) if cc.moved_to
    end
    if self.is_for_type?(:data_point_uri) ||
       self.is_for_type?(:user_added_data)
      add_taxon_concept_recipients(self.taxon_concept, recipients)
    end
  end

  def add_taxon_concept_recipients(taxon_concept, recipients)
    unless taxon_concept.blank?
      recipients << taxon_concept
      recipients << { ancestor_ids: taxon_concept.flattened_ancestor_ids }
      Collection.which_contain(taxon_concept).each do |c|
        recipients << c
      end
    end
  end

  def add_recipient_affected_by_object_curation(recipients)
    if target_is_a_data_object?
      recipients << self.data_object
      self.data_object.data_object_taxa(published: true).each do |assoc|
        next unless assoc.taxon_concept
        recipients << assoc.taxon_concept
        recipients << { ancestor_ids: assoc.taxon_concept.flattened_ancestor_ids }
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

  def add_recipient_curator_of_classification(recipients)
    if unlock?
      user.add_as_recipient_if_listening_to(:curation_on_my_watched_item, recipients)
    end
  end

  def add_recipient_author_of_curated_text(recipients)
    if target_is_a_data_object?
      if u = self.data_object.contributing_user
        u.add_as_recipient_if_listening_to(:comment_on_my_contribution, recipients)
      end
    end
  end

  # All of these "types" are actually stored as a data_object, for reasons that escape me at the time of this
  # writing.  ...But if you care to find out why, I suggest you look at the data objects controller.
  def target_is_a_data_object?
    [ ChangeableObjectType.data_object.id, ChangeableObjectType.data_objects_hierarchy_entry.id,
      ChangeableObjectType.curated_data_objects_hierarchy_entry.id, ChangeableObjectType.users_data_object.id
    ].include?(self.changeable_object_type_id) && data_object
  end

  def unlock?
    self.is_for_type?(:classification_curation) &&
      [Activity.unlock.id, Activity.unlock_with_error.id].include?(self.activity_id)
  end
end
