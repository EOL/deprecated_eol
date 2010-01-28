# TODO - ADD COMMENTS
class Synonym < SpeciesSchemaModel

  belongs_to :hierarchy
  belongs_to :hierarchy_entry
  belongs_to :language
  belongs_to :name
  belongs_to :synonym_relation
  belongs_to :vetted
  
  has_one  :taxon_concept_name
  has_many :agents_synonyms
  has_many :agents, :through => :agents_synonyms

  before_save :set_preferred
  after_update :update_taxon_concept_name
  after_create :create_taxon_concept_name
  before_destroy :set_preferred_true_for_last_synonym
  
  def self.by_taxon(taxon_id)
    return Synonym.find_all_by_hierarchy_entry_id(taxon_id, :include => [:synonym_relation, :name])
  end
  
  private
  
  def set_preferred
    tc_id = hierarchy_entry.taxon_concept_id
    count = TaxonConceptName.find_all_by_taxon_concept_id_and_language_id(tc_id, language_id).length
    if count == 0  # this is the first name in this language for the concept
      self.preferred = 1 
    elsif self.preferred?  # only reset other names to preferred=0 when this name is to be preferred
      SpeciesSchemaModel.connection.execute("UPDATE synonyms SET preferred = 0 where hierarchy_entry_id = #{hierarchy_entry_id} and  language_id = #{language_id}")
      SpeciesSchemaModel.connection.execute("UPDATE taxon_concept_names set preferred = 0 where taxon_concept_id = #{tc_id} and  language_id = #{language_id}")
    end
  end
  
  def update_taxon_concept_name
    if self.preferred?
      SpeciesSchemaModel.connection.execute("UPDATE taxon_concept_names set preferred = 1 where synonym_id=#{id}")
    end
  end

  def create_taxon_concept_name
    vern = (language_id == 0 or language_id == Language.scientific.id) ? false : true
    TaxonConceptName.create(:synonym_id => id, 
                            :language_id => language_id,
                            :name_id => name_id,
                            :preferred => self.preferred,
                            :source_hierarchy_entry_id => hierarchy_entry_id,
                            :taxon_concept_id => hierarchy_entry.taxon_concept_id,
                            :vern => vern)
  end
  
  def set_preferred_true_for_last_synonym
    tc_id = hierarchy_entry.taxon_concept_id
    TaxonConceptName.delete_all(:synonym_id => self.id)
    AgentsSynonym.delete_all(:synonym_id => self.id)
    count = TaxonConceptName.find_all_by_taxon_concept_id_and_language_id(tc_id, language_id).length
    if count == 1  # this is the first name in this language for the concept
      SpeciesSchemaModel.connection.execute("UPDATE taxon_concept_names set preferred = 1 where taxon_concept_id = #{tc_id} and  language_id = #{language_id}")
    end
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

