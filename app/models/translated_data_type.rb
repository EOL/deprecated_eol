class TranslatedDataType < ActiveRecord::Base
  belongs_to :data_type
  belongs_to :language
end
