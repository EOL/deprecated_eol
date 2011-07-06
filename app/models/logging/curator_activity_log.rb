class CuratorActivityLog < LoggingModel

  belongs_to :user
  belongs_to :changeable_object_type
  belongs_to :activity
  belongs_to :comment
  belongs_to :taxon_concept

  has_and_belongs_to_many :untrust_reasons, :join_table => "#{UntrustReason.configurations[RAILS_ENV]['database']}.curator_activity_logs_untrust_reasons"

  # use these associations carefully. They don't check the changeable object type, so you might try to grab a comment
  # when you should have grabbed an object and it won't fail.
  belongs_to :data_object, :foreign_key => :object_id
  belongs_to :affected_comment, :foreign_key => :object_id, :class_name => Comment.to_s

  validates_presence_of :user_id, :changeable_object_type_id, :activity_id, :created_at

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
      when ChangeableObjectType.users_submitted_text.id:
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
        synonym.hierarchy_entry.taxon_concept_id
      when ChangeableObjectType.users_submitted_text.id:
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

  def synonym
    Synonym.find(self['object_id'])
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
end
