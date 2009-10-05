class TaxonConceptName < SpeciesSchemaModel
  belongs_to :name
  belongs_to :taxon_concept
  belongs_to :language
  set_primary_keys :name_id, :taxon_concept_id, :source_hierarchy_entry_id

  has_many :taxa, :through => :names

  named_scope :common_preferred, :conditions => { :vern => 1, :preferred => 1 }
  named_scope :scientific_preferred, :conditions => { :vern => 0, :preferred => 1 }

  def set_preferred(val)
    update_sql([%q{UPDATE taxon_concept_names
                   SET preferred = ?
                   WHERE name_id = ? AND taxon_concept_id = ? AND source_hierarchy_entry_id = ? AND language_id = ?},
                val, name_id, taxon_concept_id, source_hierarchy_entry_id, language_id])
  end

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: taxon_concept_names
#
#  language_id               :integer(4)      not null
#  name_id                   :integer(4)      not null
#  source_hierarchy_entry_id :integer(4)      not null
#  taxon_concept_id          :integer(4)      not null
#  preferred                 :integer(1)      not null
#  vern                      :integer(1)      not null

