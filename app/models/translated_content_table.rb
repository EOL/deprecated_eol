class TranslatedContentTable < ActiveRecord::Base
  belongs_to :content_table
  belongs_to :language
end
