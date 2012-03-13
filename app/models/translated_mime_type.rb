class TranslatedMimeType < ActiveRecord::Base
  belongs_to :mime_type
  belongs_to :language
end
