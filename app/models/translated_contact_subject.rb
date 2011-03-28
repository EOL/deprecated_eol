class TranslatedContactSubject < ActiveRecord::Base
  belongs_to :contact_subject
  belongs_to :language
end
