class SynonymRelation < SpeciesSchemaModel
  CACHE_ALL_ROWS = true
  has_many :synonyms

  def self.synonym
    cached_find(:label, 'Synonym')
  end
  
  def self.common_name_ids
    cached('common_names') do
       [cached_find(:label, 'common name'),
        cached_find(:label, 'genbank common name')].compact.collect{ |sr| sr.id }
    end
  end

end
