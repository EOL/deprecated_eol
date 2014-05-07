class TranslatedUriType < ActiveRecord::Base
  belongs_to :uri_type
  belongs_to :language
end
