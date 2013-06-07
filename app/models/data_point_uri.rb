# Very stupid modle that just gives us a DataPointUri stored in the DB, for linking comments to. These are otherwise
# generated/stored in via SparQL.
class DataPointUri < ActiveRecord::Base

  attr_accessible :string

  belongs_to :taxon_concept

  has_many :comments, :as => :parent
  has_many :all_versions, :class_name => DataPointUri.to_s, :foreign_key => :uri, :primary_key => :uri
  has_many :all_comments, :class_name => Comment.to_s, :through => :all_versions, :primary_key => :uri, :source => :comments

  # Required for commentable items:
  def summary_name
    "TODO - something useful here"
  end

  def anchor
    "data_point_#{id}"
  end

end
