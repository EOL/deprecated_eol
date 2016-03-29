class PageFeature < ActiveRecord::Base
  belongs_to :taxon_concept, inverse_of: :page_feature

  # map_json is the only field in this as of this writing.

  # Given a list of IDs, mark them all as having maps:
  def self.have_maps(concept_ids)
    concept_ids.each do |concept_id|
      has_map(concept_id)
    end
  end

  # Mark a concept as having a map:
  def self.has_map(concept_id)
    if exists?(taxon_concept_id: concept_id)
      pf = find_by_taxon_concept_id(concept_id)
      pf.update_attribute(map_json: true)
    else
      PageFeature.create!(taxon_concept_id: concept_id, map_json: true)
    end
    true
  end
end
