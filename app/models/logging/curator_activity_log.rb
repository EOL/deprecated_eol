class CuratorActivityLog < LoggingModel

  include EOL::ActivityLogItem

  belongs_to :user
  belongs_to :changeable_object_type
  belongs_to :activity
  belongs_to :comment
  belongs_to :taxon_concept
  belongs_to :hierarchy_entry

  has_and_belongs_to_many :untrust_reasons, :join_table => "#{UntrustReason.configurations[RAILS_ENV]['database']}.curator_activity_logs_untrust_reasons"

  # use these associations carefully. They don't check the changeable object type, so you might try to grab a comment
  # when you should have grabbed an object and it won't fail.
  belongs_to :data_object, :foreign_key => :object_id
  belongs_to :synonym, :foreign_key => :object_id
  belongs_to :affected_comment, :foreign_key => :object_id, :class_name => Comment.to_s

  named_scope :notifications_not_prepared, :conditions => "notifications_prepared_at IS NULL"

  validates_presence_of :user_id, :changeable_object_type_id, :activity_id, :created_at

  after_create :log_activity_in_solr

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
          raise "Synonym #{synonym.id} does not have a HierarchyEntry"
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
    EOL::Solr::ActivityLog.index_activities(base_index_hash, activity_logs_affected)
  end

  def activity_logs_affected
    logs_affected = {}
    # activity feed of user taking action
    logs_affected['User'] = [ self.user_id ]

    # action on a concept
    if self.changeable_object_type_id == ChangeableObjectType.synonym.id
      logs_affected['TaxonConcept'] = [ self.taxon_concept_id ]
      logs_affected['AncestorTaxonConcept'] = self.taxon_concept.flattened_ancestor_ids
      logs_affected['Synonym'] = [ self.object_id ]
      Collection.which_contain(self.taxon_concept).each do |c|
        logs_affected['Collection'] ||= []
        logs_affected['Collection'] << c.id
      end

    # action on a data object
    elsif [ ChangeableObjectType.data_object.id, ChangeableObjectType.data_objects_hierarchy_entry.id,
            ChangeableObjectType.curated_data_objects_hierarchy_entry.id, ChangeableObjectType.users_data_object.id
            ].include?(self.changeable_object_type_id)
      logs_affected['DataObject'] = [ self.object_id ]
      self.data_object.curated_hierarchy_entries.each do |he|
        logs_affected['TaxonConcept'] ||= []
        logs_affected['TaxonConcept'] << he.taxon_concept_id
        logs_affected['AncestorTaxonConcept'] ||= []
        logs_affected['AncestorTaxonConcept'] |= he.taxon_concept.flattened_ancestor_ids
      end
      Collection.which_contain(self.data_object).each do |c|
        logs_affected['Collection'] ||= []
        logs_affected['Collection'] << c.id
      end
    end
    logs_affected
  end

  def notify_listeners
    # TODO
  end

end
