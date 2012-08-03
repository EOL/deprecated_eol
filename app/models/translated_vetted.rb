class TranslatedVetted < ActiveRecord::Base
  self.table_name = "translated_vetted"
  belongs_to :vetted
  belongs_to :language
end
