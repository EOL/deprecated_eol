class CollectionFromList < ActiveRecord::Base
  belongs_to :collection # may be blank
  has_many :strings, class_name: "CollectionFromListString"

  def find_matches
    strings.each(&:find_matches)
  end

end