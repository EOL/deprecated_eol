class DataSearchFileEquivalent < ActiveRecord::Base
  belongs_to :data_search_file
  belongs_to :known_uri
end
