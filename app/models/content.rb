# This is a class used by Tramea.
# Because this class has denormalized fields, it must be updated when:
# * The taxon_concept's exemplar node (preferred hierarchy) is changed
# * The preferred hierarchy / exemplar node is re-harvested
class Content < ActiveRecord::Base
  belongs_to :taxon_concept
  belongs_to :to, polymorphic: true # (Image, Article, etc)
  # TODO: It might be nice, here, to indicate who added the content,
  # whether it was a ContentPartner or a curator

  def self.from_data_object_taxon(dot, target)
    create(
      taxon_concept_id: dot.taxon_concept_id,
      to: target,
      scientific_name: dot.hierarchy_entry.name.string,
      hierarchy_entry_id: dot.hierarchy_entry_id, # CAN BE NIL. (ie: user-added article)
      user_id: dot.user_id, # Could be nil.
      trusted: dot.vetted_id == Vetted.trusted.id,
      hidden: dot.visibility_id != Visilibity.visible.id,
      exemplar: target.try(:is_exemplar_for?, taxon)
    )
  end
end
