# NOTE - you can get a list of all the possible collection item types with this command:
# git grep "has_many :collection_items, :as" app
class CollectionItem < ActiveRecord::Base

  belongs_to :collection, :touch => true
  belongs_to :object, :polymorphic => true
  belongs_to :added_by_user, :class_name => User.to_s, :foreign_key => :added_by_user_id
  has_and_belongs_to_many :refs

  scope :collections, :conditions => {:object_type => 'Collection'}
  scope :communities, :conditions => {:object_type => 'Community'}
  scope :data_objects, :conditions => {:object_type => 'DataObject'}
  scope :taxa, :conditions => {:object_type => 'TaxonConcept'}
  scope :users, :conditions => {:object_type => 'User'}
  scope :annotated, :conditions => 'annotation IS NOT NULL AND annotation != ""'

  # Note that it doesn't validate the presence of collection.  A "removed" collection item still exists, so we have a
  # record of what it used to point to (see CollectionsController#destroy). (Hey, the alternative is to have a bunch
  # of unused fields in collection_activity_logs, so it's actually better to have these "zombie" rows here!)
  validates_presence_of :object_id, :object_type
  validates_uniqueness_of :object_id, :scope => [:collection_id, :object_type],
    :message => I18n.t(:item_not_added_already_in_collection), :if => Proc.new { |ci| ci.collection_id }

  # Note we DO NOT update relevance on the collection on save or delete, since we sometimes add/delete 1000 items at
  # a time, and that would be a disaster, since the collection only need be recalculated once.
  after_save     :index_collection_item_in_solr
  after_update   :update_collection_relevance_if_annotation_switched
  before_destroy :remove_collection_item_from_solr

  # Information about how collection items interface with solr and views and the like...
  def self.types
    @types ||= {:taxa =>        {:facet => 'TaxonConcept', :i18n_key => "taxa"},
                :text =>        {:facet => 'Text',         :i18n_key => "articles"},
                :images =>      {:facet => 'Image',        :i18n_key => "images"},
                :sounds =>      {:facet => 'Sound',        :i18n_key => "sounds"},
                :videos =>      {:facet => 'Video',        :i18n_key => "videos"},
                :communities => {:facet => 'Community',    :i18n_key => "communities"},
                :people =>      {:facet => 'User',         :i18n_key => "people"},
                :collections => {:facet => 'Collection',   :i18n_key => "collections"}}
  end

  def can_be_updated_by?(user_wanting_access)
    user_wanting_access.can_edit_collection?(collection)
  end
  # Using has_one :through didn't work:
  def community
    return nil unless collection
    return nil unless collection.community
    return collection.community
  end

  def index_collection_item_in_solr
    return unless $INDEX_RECORDS_IN_SOLR_ON_SAVE
    remove_collection_item_from_solr
    # If there is no collection associated with this collection item, it is meant for historical indexing only, and
    # there is no need to index this in solr.  ...In fact, it had better not be indexed!
    if collection_id
      begin
        solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_COLLECTION_ITEMS_CORE)
      rescue Errno::ECONNREFUSED => e
        puts "** WARNING: Solr connection failed."
        return nil
      end
      solr_connection.create(solr_index_hash)
    end
  end

  def solr_index_hash
    params = {}
    params['collection_item_id'] = self.id
    params['object_type'] = (self.object_type == 'DataObject') ? self.object.data_type.simple_type('en') : self.object_type
    params['object_id'] = self.object_id
    params['collection_id'] = self.collection_id || 0
    params['annotation'] = self.annotation || ''
    params['added_by_user_id'] = self.added_by_user_id || 0
    params['date_created'] = self.created_at.solr_timestamp rescue nil
    params['date_modified'] = self.updated_at.solr_timestamp rescue nil
    params['sort_field'] = self.sort_field

    case self.object.class.name
    when "TaxonConcept"
      unless self.object.entry && self.object.entry.name && self.object.entry.name.canonical_form
        raise EOL::Exceptions::InvalidCollectionItemType.new(I18n.t(:cannot_index_collection_item_type_error,
                                                                    :type => 'Missing Hierarchy Entry'))
      end
      params['title'] = self.object.entry.name.canonical_form.string
    when "User"
      params['title'] = self.object.username
    when "DataObject"
      params['title'] = self.object.best_title
      params['data_rating'] = self.object.safe_rating
    when "Community"
      params['title'] = self.object.name
    when "Collection"
      params['title'] = self.object.name
    else
      raise EOL::Exceptions::InvalidCollectionItemType.new(I18n.t(:cannot_index_collection_item_type_error,
                                                                  :type => self.object.class.name))
    end

    params['data_rating'] ||= 0
    params['richness_score'] ||= 0
    # this is a strange thing to do as only TaxonConcepts have richness, but putting this inside the case switch
    # above was giving me other mysterious errors
    if self.object.class.name == "TaxonConcept" && self.object.taxon_concept_metric && !self.object.taxon_concept_metric.richness_score.blank?
      params['richness_score'] = self.object.taxon_concept_metric.richness_score
    end
    return params
  end

  def remove_collection_item_from_solr
    return unless $INDEX_RECORDS_IN_SOLR_ON_SAVE
    begin
      solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_COLLECTION_ITEMS_CORE)
    rescue Errno::ECONNREFUSED => e
      puts "** WARNING: Solr connection failed."
      return nil
    end
    solr_connection.delete_by_query("collection_item_id:#{self.id}")
  end

  # This is somewhat expensive (can take a second to run), so use sparringly.
  def update_collection_relevance
    collection.set_relevance if collection
  end

  # Because doing so is expensive, we check to make sure there's a need (which would only be if annotation was added
  # or removed)
  def update_collection_relevance_if_annotation_switched
    if changed?
      if changes.has_key?('annotation')
        (before, after) = changes['annotation']
        before.gsub(/\s+$/, '') if before
        after.gsub(/\s+$/, '') if after
        if (before.blank? && ! after.blank?) || (after.blank? && ! before.blank?)
          update_collection_relevance
        end
      end
    end
  end

end
