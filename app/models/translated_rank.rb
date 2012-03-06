class TranslatedRank < ActiveRecord::Base
  belongs_to :rank
  belongs_to :language
end
