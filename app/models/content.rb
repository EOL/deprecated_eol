# This is a class used by Tramea.
#
# This is basically a replacement for Solr's data_objects core, if we did it right.
#
# Because this class has denormalized fields, it must be updated when:
# * The taxon_concept's exemplar node (preferred hierarchy) is changed
# * The preferred hierarchy / exemplar node is re-harvested
class Content < ActiveRecord::Base
  belongs_to :taxon_concept
  belongs_to :to, polymorphic: true # (Image, Article, etc)
  belongs_to :hierarchy_entry # Not if it's user-added text.
  belongs_to :page,
      primary_key: "taxon_concept_id",
      foreign_key: "taxon_concept_id"
  belongs_to :node,
      primary_key: "hierarchy_entry_id",
      foreign_key: "hierarchy_entry_id"

  has_many :content_curations

  # NOTE: if ANY of these are set, it implies that the object was curated
  # (automatically or not); check the content_curations. And, yes, some of these
  # are mutually exclusive, but that must be enforced at the code level.
  scope :trusted, -> { where(trusted: true) }
  scope :hidden, -> { where(hidden: true) }
  scope :shown, -> { where(shown: true) }
  scope :untrusted, -> { where(untrusted: true) }

  scope :ancestor, -> { where(ancestor: true) }
  scope :inherited, -> { where(ancestor: true) } # Pesudo-alias for #ancestor
  scope :primary, -> { where(ancestor: false) }

  # NOTE: While we want to make sure that all of the page's ancestors get a
  # content like this one, we don't want to take that responsibility here, as
  # that could result in inifinite loops as we create missing pages. Best if the
  # page handles all of the relationships for its ancestors, since it is aware
  # of what it has created.
  def self.from_data_object_taxon(dot, target)
    return find_by_data_object_id_and_taxon_concept_id if
      exists?(taxon_concept_id: dot.taxon_concept_id,
        data_object_id: target.data_object_id)
    curations = CuratorActivityLog.where(
      hierarchy_entry_id: dot.hierarchy_entry_id,
      target_id: target.data_object_id
    )
    content = create(
      taxon_concept_id: dot.taxon_concept_id,
      to: target,
      data_object_id: target.data_object_id,
      scientific_name: dot.hierarchy_entry.name.string,
      # If it was added by a user, I do NOT want this associaiton, it's not
      # trustworthy:
      hierarchy_entry_id: dot.users_data_object? ?
        nil :
        dot.hierarchy_entry_id,
      user_id: dot.user_id, # Could be nil.
      trusted: dot.vetted_id == Vetted.trusted.id,
      hidden: dot.visibility_id != Visilibity.visible.id,
      # It was only untrusted/shown if someone DID that:
      untrusted: (dot.vetted_id != Vetted.trusted.id &&
        curations.any? { |c| c.activity_id == Activity.untrusted.id }),
      shown: (dot.visibility_id == Visilibity.visible.id &&
        curations.any? { |c| c.activity_id == Activity.show.id }),
      ancestor: false,
      exemplar: target.try(:is_exemplar_for?, taxon)
    )
    curations.each do |curation|
      # DON'T add inappropriate curations; should be deletions:
      next if curation.activity_id == Activity.inappropriate.id
      # Adding associations isn't handled here:
      next if curation.activity_id == Activity.add_association.id
      # Same:
      next if curation.activity_id == Activity.remove_association.id
      ContentCuration.from_curator_activity_log(curation, content)
    end
    content
  end
end
