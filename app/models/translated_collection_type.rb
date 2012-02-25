class TranslatedCollectionType < ActiveRecord::Base
  belongs_to :collection_type
  belongs_to :language
end
