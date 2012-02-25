class TaxonConceptContent < ActiveRecord::Base
  set_table_name 'taxon_concept_content'
  belongs_to :taxon_concept
  belongs_to :image_object, :class_name => DataObject.to_s, :foreign_key => :image_object_id
  set_primary_key :taxon_concept_id
end