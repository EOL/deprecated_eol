# Handles the hum-drum of maintaining collections in Solr.
# NOTE - you shouldn't be calling any instance methods at all. Only use the class methods, or you're duplicating
# effort. I can't make them private, though, because they are called from the class methods...
class SolrCollections

  attr_reader :connection

  # Okay, all these class methods duplicating instance methods are annoying, but useful. I couldn't think of
  # a reasonable way to generalize it, short of method_missing, which seemed like overkill.

  def self.remove_collection(collection)
    return(nil) unless $INDEX_RECORDS_IN_SOLR_ON_SAVE
    solr = SolrCollections.new
    solr.remove_collection(collection) if solr
  end

  def self.remove_collection_items(items)
    return(nil) unless $INDEX_RECORDS_IN_SOLR_ON_SAVE
    solr = SolrCollections.new
    solr.remove_collection_items(items) if solr
  end

  def self.reindex_collection(collection)
    return(nil) unless $INDEX_RECORDS_IN_SOLR_ON_SAVE
    solr = SolrCollections.new
    if solr
      solr.remove_collection(collection)
      solr.index_collection(collection)
    end
  end

  def self.reindex_collection_items(items)
    return(nil) unless $INDEX_RECORDS_IN_SOLR_ON_SAVE
    solr = SolrCollections.new
    if solr
      solr.remove_collection_items(items)
      solr.index_collection_items(items)
    end
  end

  def initialize
    begin
      @connection = SolrAPI.new($SOLR_SERVER, $SOLR_COLLECTION_ITEMS_CORE)
    rescue Errno::ECONNREFUSED => e
      logger.warn "** Solr connection failed."
      return nil
    end
  end

  def index_collection(collection)
    # TODO - re-write this to be a more efficient POST:
    collection.collection_items.each do |item|
      connection.create(collection_item_hash(item))
    end
  end

  def index_collection_items(items)
    # TODO - re-write this to be a more efficient POST:
    items.each do |item|
      # NOTE - If there is no collection associated with a collection item, it is meant for historical indexing only,
      # and there is no need to index it in solr.  ...In fact, it had better not be indexed!
      connection.create(collection_item_hash(item)) if item.collection_id
    end
  end

  def remove_collection(collection)
    connection.delete_by_query("collection_id:#{collection.id}")
  end

  # NOTE that the size of items is limited by the number of collection items shown on a page, which
  # should be a reasonable number.
  def remove_collection_items(items)
    connection.delete_by_query("collection_item_id:#{items.map(&:id).join(',')}")
  end

  # This builds the hash that Solr expects to see for each collection item. This may not be the best
  # place for this logic, but ATM this is the only place it's being used.
  def collection_item_hash(item)
    unless item.collected_item.respond_to?(:collected_title)
      raise EOL::Exceptions::InvalidCollectionItemType.new(I18n.t(:cannot_index_collection_item_type_error,
                                                                  :type => item.collected_item.class.name))
    end
    
    # Some items (q.v. DataObject) want to store a more specific type than simply their class name:
    # TODO - we could just duck-type this on each collectable class.
    item_collected_item_type = item.collected_item.respond_to?(:collected_type) ?
      item.collected_item.collected_type :
      item.collected_item_type

    params = {'data_rating' => 0, 'richness_score' => 0}
    params['annotation'] = item.annotation || ''
    params['added_by_user_id'] = item.added_by_user_id || 0
    params['collection_id'] = item.collection_id || 0
    params['collection_item_id'] = item.id
    params['data_rating'] = item.collected_item.safe_rating if item.collected_item.is_a?(DataObject)
    params['date_created'] = item.created_at.solr_timestamp rescue '1960-01-01T00:00:01Z'
    params['date_modified'] = item.updated_at.solr_timestamp rescue '1960-01-01T00:00:01Z'
    params['link_type_id'] = item.collected_item.link_type.id if item_collected_item_type == 'Link'
    params['object_type'] = item_collected_item_type
    params['object_id'] = item.collected_item_id
    params['richness_score'] = item.collected_item.richness if item.respond_to?(:richness) && item.has_richness?
    params['sort_field'] = item.sort_field unless item.sort_field.blank?
    params['title'] = item.collected_item.collected_title
    params
  end

end
