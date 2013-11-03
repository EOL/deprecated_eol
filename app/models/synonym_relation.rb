class SynonymRelation < ActiveRecord::Base

  uses_translations
  has_many :synonyms

  include NamedDefaults
  set_defaults :label, ['Synonym', 'common name', 'genbank common name']

  def self.common_name_ids
    cached('common_names') do
       [SynonymRelation.common_name, SynonymRelation.genbank_common_name].compact.map(&:id)
    end
  end

end
