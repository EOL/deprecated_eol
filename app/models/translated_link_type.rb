class TranslatedLinkType < ActiveRecord::Base
  belongs_to :link_type
  belongs_to :language
end
