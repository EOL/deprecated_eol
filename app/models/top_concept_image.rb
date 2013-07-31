# This class shouldn't be used.  :)  It's really just here so that fixtures load into the right database.  Meaning,
# this *class* doesn't perform any special function.  The top_images table, however, is used for denormalized
# searches on (normal, vetted, visible, published) images. That table is referenced by
# DataObject#cached_images_for_taxon().  That table is *built* using PHP, so you will not see any other ref to it.
class TopConceptImage < ActiveRecord::Base
  self.primary_keys = :taxon_concept_id, :data_object_id
  belongs_to :taxon_concept
  belongs_to :data_object

  def self.push_to_top(taxon_concept, data_object)
    top_image = TopConceptImage.where(taxon_concept_id: taxon_concept.id, data_object_id: data_object.id).first
    old_view_order = top_image.view_order if top_image
    TopConceptImage.delete_all(taxon_concept_id: taxon_concept.id, data_object_id: data_object.id)
    TopConceptImage.connection.execute("UPDATE top_concept_images SET view_order=view_order+1 WHERE taxon_concept_id=#{taxon_concept.id}" +
                                         (old_view_order ? " AND view_order < #{old_view_order}" : ''));
    TopConceptImage.create(taxon_concept: taxon_concept, data_object: data_object, view_order: 1)
  end

end
