# Very stupid modle that just gives us a DataPointUri stored in the DB, for linking comments to. These are otherwise
# generated/stored in via SparQL.
class DataPointUri < ActiveRecord::Base

  attr_accessible :string

  belongs_to :taxon_concept

  has_many :comments, :as => :parent

  # Required for commentable items:
  def summary_name
    "TODO - something useful here"
  end

  def anchor
    "user_added_data_#{id}"
  end

end
