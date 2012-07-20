class SynonymRelation < ActiveRecord::Base
  uses_translations
  has_many :synonyms

  def self.synonym
    cached_find_translated(:label, 'Synonym', 'en')
  end
  
  def self.common_name_ids
    cached_with_local_cache('common_names') do
       [cached_find_translated(:label, 'common name', 'en'),
        cached_find_translated(:label, 'genbank common name', 'en')].compact.collect{ |sr| sr.id }
    end
  end

end
