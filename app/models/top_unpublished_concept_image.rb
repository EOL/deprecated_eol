# This class shouldn't be used.  :)  It's really just here so that fixtures load into the right database.  Meaning, this *class*
# doesn't perform any special function.  The top_iages table, however, is used for denormalized searches on (normal, vetted, visible,
# published) images. That table is referenced by DataObject#cached_images_for_taxon().  That table is *built* using PHP, so you will
# not see any other ref to it.
class TopUnpublishedConceptImage < SpeciesSchemaModel
  set_primary_keys :taxon_concept_id, :data_object_id
  belongs_to :taxon_concept
  belongs_to :data_object
end
