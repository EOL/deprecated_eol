class TranslatedLanguage < ActiveRecord::Base
  # this is an unfortunate consequence of translating all languages in every language
  belongs_to :original_language, :class_name => Language.to_s, :foreign_key => 'original_language_id'
  belongs_to :language
end
