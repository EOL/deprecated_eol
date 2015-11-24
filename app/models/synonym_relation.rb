class SynonymRelation < ActiveRecord::Base

  uses_translations
  has_many :synonyms

  include Enumerated
  enumerated :label, [ 'Synonym', 'common name', 'genbank common name',
    'blast name', 'genbank acronym', 'acronym']

  def self.common_name_ids
    cached('common_names') do
       [common_name, genbank_common_name].compact.map(&:id)
    end
  end

  def self.common_and_acronym_ids
    cached('non_tc_name_ids') do
      common_name_ids + [blast_name, genbank_acronym, acronym].compact.map(&:id)
    end
  end

end
