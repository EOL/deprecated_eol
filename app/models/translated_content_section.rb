class TranslatedContentSection < ActiveRecord::Base
  belongs_to :content_section
  belongs_to :language
end
