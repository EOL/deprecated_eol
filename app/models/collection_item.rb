# NOTE - you can get a list of all the possible collection item types with this command:
# git grep "has_many :collection_items, :as" app
class CollectionItem < ActiveRecord::Base

  belongs_to :collection
  belongs_to :object, :polymorphic => true
  belongs_to :added_by_user, :class_name => User.to_s, :foreign_key => :added_by_user_id

  # Note that it doesn't validate the presence of collection.  A "removed" collection item still exists, so we have a
  # record of what it used to point to (see CollectionsController#destroy). (Hey, the alternative is to have a bunch
  # of unused fields in collection_activity_logs, so it's actually better to have these "zombie" rows here!)
  validates_presence_of :object_id, :object_type
  validates_uniqueness_of :object_id, :scope => [:collection_id, :object_type],
    :message => I18n.t(:item_not_added_already_in_collection)
  
  after_save :index_collection_item_in_solr
  before_destroy :remove_collection_item_from_solr
  
  # Using has_one :through didn't work:
  def community
    return nil unless collection
    return nil unless collection.community
    return collection.community
  end
  
  def index_collection_item_in_solr
    remove_collection_item_from_solr
    begin
      solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_COLLECTION_ITEMS_CORE)
    rescue Errno::ECONNREFUSED => e
      puts "** WARNING: Solr connection failed."
      return nil
    end
    
    params = {}
    params['collection_item_id'] = self.id
    params['object_type'] = (self.object_type == 'DataObject') ? self.object.data_type.simple_type('en') : self.object_type
    params['object_id'] = self.object_id
    params['collection_id'] = self.collection_id || 0
    params['annotation'] = self.annotation || ''
    params['added_by_user_id'] = self.added_by_user_id || 0
    params['date_created'] = self.created_at.solr_timestamp rescue nil
    params['date_modified'] = self.updated_at.solr_timestamp rescue nil
    
    case self.object.class.name
    when "TaxonConcept"
      params['title'] = self.object.entry.name.canonical_form.string
    when "User"
      params['title'] = self.object.username
    when "DataObject"
      params['title'] = self.object.best_title
      params['data_rating'] = self.object.data_rating || 0
    when "Community"
      params['title'] = self.object.name
    when "Collection"
      params['title'] = self.object.name
    else
      raise EOL::Exceptions::InvalidCollectionItemType.new("I cannot index a collection item from a #{self.object.class.name}")
    end
    
    params['data_rating'] ||= 0
    params['richness_score'] ||= 0
    # this is a strange thing to do as only TaxonConcepts have richness, but putting this inside the case switch
    # above was giving me other mysterious errors
    # if self.object.class.name == "TaxonConcept" && self.object.taxon_concept_metric && !self.object.taxon_concept_metric.richness_score.blank?
    #   params['richness_score'] = 0
    # end
    solr_connection.create(params)
  end
  
  def remove_collection_item_from_solr
    begin
      solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_COLLECTION_ITEMS_CORE)
    rescue Errno::ECONNREFUSED => e
      puts "** WARNING: Solr connection failed."
      return nil
    end
    solr_connection.delete_by_query("collection_item_id:#{self.id}")
  end

end
