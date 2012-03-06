class TranslatedLicense < ActiveRecord::Base
  belongs_to :license
  belongs_to :language
end
