class LanguageGroup < ActiveRecord::Base
  has_many :languages
  belongs_to :representative_language, :class_name => Language.to_s

  attr_accessible :representative_language_id
end
