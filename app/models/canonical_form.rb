# A canonical form of a scientific name is the name parts without authorship,
# rank information, or anything except the latinized name parts. These are for
# the most part algorithmically generated. 
#
# Every Name should have a CanonicalForm.
class CanonicalForm < ActiveRecord::Base
  has_many :names
  belongs_to :name # Yes, really.
end
