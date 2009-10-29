# This class shouldn't be used.  :)  It's really just here so that fixtures load into the right database.  Meaning,
# this *class* doesn't perform any special function.  The top_images table, however, is used for denormalized
# searches on (normal, vetted, visible, published) images. That table is referenced by
# DataObject#cached_images_for_taxon().  That table is *built* using PHP, so you will not see any other ref to it.
class TopSpeciesImage < SpeciesSchemaModel
  set_primary_keys :hierarchy_entry_id, :data_object_id
  belongs_to :hierarchy_entry
  belongs_to :data_object
end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: top_images
#
#  data_object_id     :integer(4)      not null
#  hierarchy_entry_id :integer(4)      not null
#  view_order         :integer(2)      not null

