class AppendDotcWithMissingEntriesFromUdo < ActiveRecord::Migration

  def self.up
    UsersDataObject.all.select{ |udo| udo.data_object.published? }.each do |udo|
      DataObjectsTaxonConcept.find_or_create_by_taxon_concept_id_and_data_object_id(udo.taxon_concept_id, udo.data_object_id)
    end
  end

  def self.down
    # Doesn't really matter.
  end

end
