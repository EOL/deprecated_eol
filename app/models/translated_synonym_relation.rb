class TranslatedSynonymRelation < ActiveRecord::Base
  belongs_to :synonym_relation
  belongs_to :language
end
