# Represents an association between a data object and a taxon concept.
# In practice, this can be built from:
#   DataObjectHierarchyEntry
#   CuratedDataObjectHierarchyEntry
#   UsersDataObject
# For more information, see the model spec. You... *are* looking at the specs to learn how things work, right?
class DataObjectTaxon

  include EOL::CuratableAssociation

  attr_accessor :source, :hierarchy_entry, :vetted, :visibility, :associated_by_curator, :name, :taxon_concept,
                :data_object, :user, :hierarchy_entry_id, :vetted_id, :visibility_id, :user_id, :taxon_concept_id,
                :data_object_id, :user_id

  def self.default_sort(data_object_taxa)
    data_object_taxa.sort_by do |dot|
      vetted_view_order = dot.vetted.blank? ? 0 : dot.vetted.view_order
      visibility_view_order = dot.visibility.blank? ? 0 : dot.visibility.view_order
      [ (dot.published * -1),
        visibility_view_order,
        vetted_view_order ]
    end
  end

  def italicized_attributed_title
    taxon_concept.italicized_attributed_title
  end

  def italicized_unattributed_title
    taxon_concept.italicized_unattributed_title
  end

  def non_italicized_unattributed_title
    taxon_concept.non_italicized_unattributed_title
  end

  def initialize(source)
    return nil unless source
    @source = source
    read_source
  end

  def users_data_object?
    source.is_a? UsersDataObject
  end

  def data_objects_hierarchy_entry?
    source.is_a? DataObjectsHierarchyEntry
  end

  def curated_data_objects_hierarchy_entry?
    source.is_a? CuratedDataObjectsHierarchyEntry
  end

  def published
    users_data_object? ? taxon_concept.published : hierarchy_entry.published
  end
  alias :published? :published

  def hierarchy
    users_data_object? ? taxon_concept.entry.hierarchy : hierarchy_entry.hierarchy
  end

  # Views make the assumption that the ID is the hierarchy_entry_id if it's available, or the UDO id otherwise.
  def id
    hierarchy_entry_id ? hierarchy_entry_id : source.id
  end

  # TODO - change this to #name, if #name really isn't used (and I don't think it is).
  def italicized_name
    users_data_object? ? taxon_concept.title : hierarchy_entry.italicized_name
  end

  def title_canonical
    users_data_object? ? taxon_concept.title_canonical : hierarchy_entry.title_canonical
  end

  def title_canonical_italicized
    users_data_object? ? taxon_concept.title_canonical_italicized : hierarchy_entry.title_canonical_italicized
  end

  # Returns true IFF this HE was included in a set of HEs because a curator
  # added the association.  See DataObject.curated_hierarchy_entries
  def by_curated_association?
    associated_by_curator
  end

  # Used in views...
  def can_be_deleted_by?(requestor)
    return true if by_curated_association? && (requestor.master_curator? || associated_by_curator == requestor)
  end

  # To retrieve the reasons provided while untrusting an association
  def untrust_reason_ids
    @untrust_reasons ||= reason_ids(Activity.untrusted)
  end

  # To retrieve the reasons provided while hiding an association
  def hide_reason_ids
    @hide_reasons ||= reason_ids(Activity.hide)
  end

  # TODO - can we pull in Rails's delegate method to do this kind of stuff?
  protected

  def update_attributes(hash)
    # NOTE - the #reload here is aboslutely necessary. I don't know why... but it totally does NOTHING without it.
    retval = source.reload.update_attributes(hash)
    read_source # Now we need to update ourselves!
    retval
  end

  def vetted_by=(user)
    source.vetted_by = user
  end

  private

  def read_source
    @hierarchy_entry = source.hierarchy_entry if source.respond_to?(:hierarchy_entry)
    @vetted = source.vetted
    @visibility = source.visibility
    @data_object = source.data_object
    @user = source.user if source.respond_to?(:user)
    @associated_by_curator = @user if @user && @user.is_curator? # Not all users are curators, of course.
    # TODO - when is this used? I don't think it is.
    @name = @hierarchy_entry.name if @hierarchy_entry.respond_to?(:name)
    @taxon_concept = source.taxon_concept
    # IDs are really only used by Solr indexing, but are here for convenience (and Least Surprise):
    @hierarchy_entry_id = @hierarchy_entry.id if @hierarchy_entry.is_a? HierarchyEntry
    @vetted_id = @vetted.id if @vetted.is_a? Vetted
    @visibility_id = @visibility.id if @visibility.is_a? Visibility
    @user_id = @user.id if @user.is_a? User
    @taxon_concept_id = @taxon_concept.id if @taxon_concept.is_a? TaxonConcept
    @data_object_id = @data_object.id if @data_object.is_a? DataObject
  end


  def reason_ids(activity)
    method = "find_all_by_data_object_guid_and_changeable_object_type_id_and_activity_id"
    method << "_and_hierarchy_entry_id" if hierarchy_entry
    args = [source.guid, ChangeableObjectType.send(source.class.name.underscore).id, activity.id]
    args << hierarchy_entry.id if hierarchy_entry
    # TODO - #last is weak, here: we should only be selecting one and specifying an order...
    log = CuratorActivityLog.send(method, *args).last # #last is supposed to give us the most recent...
    log ? log.untrust_reasons.map(&:id) : []
  end

end
