# Very stupid modle that just gives us a DataPointUri stored in the DB, for linking comments to. These are otherwise
# generated/stored in via SparQL.
class DataPointUri < ActiveRecord::Base

  include EOL::CuratableAssociation

  attr_accessible :string

  belongs_to :taxon_concept
  belongs_to :vetted
  belongs_to :visibility

  has_many :comments, :as => :parent
  has_many :all_versions, :class_name => DataPointUri.to_s, :foreign_key => :uri, :primary_key => :uri
  has_many :all_comments, :class_name => Comment.to_s, :through => :all_versions, :primary_key => :uri, :source => :comments

  # Required for commentable items. NOTE - This requires four queries from the DB, unless you preload the
  # information.  TODO - preload these:
  # TaxonConcept Load (10.3ms)  SELECT `taxon_concepts`.* FROM `taxon_concepts` WHERE `taxon_concepts`.`id` = 17
  # LIMIT 1
  # TaxonConceptPreferredEntry Load (15.0ms)  SELECT `taxon_concept_preferred_entries`.* FROM
  # `taxon_concept_preferred_entries` WHERE `taxon_concept_preferred_entries`.`taxon_concept_id` = 17 LIMIT 1
  # HierarchyEntry Load (0.8ms)  SELECT `hierarchy_entries`.* FROM `hierarchy_entries` WHERE
  # `hierarchy_entries`.`id` = 12 LIMIT 1
  # Name Load (0.5ms)  SELECT `names`.* FROM `names` WHERE `names`.`id` = 25 LIMIT 1
  def summary_name
    I18n.t(:data_point_uri_summary_name, :taxon => taxon_concept.summary_name)
  end

  def anchor
    "data_point_#{id}"
  end

end
