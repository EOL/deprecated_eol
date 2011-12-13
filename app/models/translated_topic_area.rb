class TranslatedTopicArea < ActiveRecord::Base
  belongs_to :topic_area
  belongs_to :language
end

