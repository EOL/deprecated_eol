# TODO - ADD COMMENTS
class Synonym < SpeciesSchemaModel

  belongs_to :hierarchy
  belongs_to :hierarchy_entry
  belongs_to :language
  belongs_to :name
  belongs_to :synonym_relation
  belongs_to :vetted
  
  has_many :agents_synonyms

  def self.by_taxon(taxon_id)
    return Synonym.find_all_by_hierarchy_entry_id(taxon_id, :include => [:synonym_relation, :name])
  end

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: synonyms
#
#  id                  :integer(4)      not null, primary key
#  hierarchy_entry_id  :integer(4)      not null
#  hierarchy_id        :integer(2)      not null
#  language_id         :integer(2)      not null
#  name_id             :integer(4)      not null
#  synonym_relation_id :integer(1)      not null
#  preferred           :integer(1)      not null

