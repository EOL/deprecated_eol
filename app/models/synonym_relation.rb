class SynonymRelation < SpeciesSchemaModel

  has_many :synonyms

  def self.synonym
    Rails.cache.fetch('synonym_relations/synonym') do
      self.find_by_label('Synonym')
    end
  end
  
  def self.common_name_ids
    Rails.cache.fetch('synonym_relations/common_names') do
       [SynonymRelation.find_or_create_by_label('common name').id,
        SynonymRelation.find_or_create_by_label('genbank common name').id]
    end
  end
  

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: synonym_relations
#
#  id    :integer(2)      not null, primary key
#  label :string(255)     not null

