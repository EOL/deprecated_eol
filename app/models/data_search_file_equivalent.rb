class DataSearchFileEquivalent < ActiveRecord::Base
  belongs_to :data_search_files
  belongs_to :known_uri
end
