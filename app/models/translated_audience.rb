class TranslatedAudience < ActiveRecord::Base
  belongs_to :audience
  belongs_to :language
end
