# NOTE - This is an EXCEEDINGLY expensive calculation! It can take several seconds for a single collection... much
# longer with huge collections...
#
# You should only ever run this in the background.  Seriously.  Don't make users wait for this!

class CollectionRelevanceCalculator

  @queue = 'notifications' # TODO - something else?

  attr_accessor :collection

  # TODO - this logging is miserable and doesn't cover enough. Improve.
  def self.perform(id)
    Rails.logger.error "++ #{Time.now.strftime("%F %T")} - CollectionRelevanceCalculator performing for collection ##{id}."
    begin
      CollectionRelevanceCalculator.new(Collection.find(id)).set_relevance
    rescue => e
      Rails.logger.error "++ #{Time.now.strftime("%F %T")} - ERROR: #{e.message}\n #{e.backtrace[0..10].join("\n  ")})."
    end
    Rails.logger.error "++ #{Time.now.strftime("%F %T")} - Done."
  end

  def initialize(collection)
    @collection = collection
  end

  # This should set the relevance attribute score between 0 and 100.  Use this sparringly, it's expensive to calculate:
  def set_relevance
    return 0 if collection.watch_collection? # Watch collections are irrelevant.
    @taxa_count = collection.taxa_count
    return 0 if @taxa_count <= 0 # Collections with no taxa (ie: friend lists and the like) are irrelevant.
    # Each sub-category should return a score between 1 and 100:
    score = (calculate_feature_relevance * 0.4) + (calculate_taxa_relevance * 0.4) + (calculate_item_relevance * 0.2)
    return 0 if score <= 0
    return 100 if score >= 100
    collection.update_attributes(relevance: score.to_i)
  end

private

  def calculate_feature_relevance
    features = count_containing_collections(is_featured: true)
    times_featured_score = case features
                           when 0
                             0
                           when 1..25
                             2 * features
                           else
                             50
                           end
    collected = count_containing_collections(is_featured: false)
    times_collected_score = case collected
                            when 0
                              0
                            when 1..30
                              collected
                            else
                              30
                            end
    is_focus_list_score = collection.focus? ? 20 : 0
    score = times_featured_score + times_collected_score + is_focus_list_score
    return 0 if score <= 0
    return 100 if score >= 100
    return score.to_i
  end

  # Extremely focused list = high score ... too many taxa = not as relevant.
  def calculate_taxa_relevance
    taxa = @taxa_count || collection.taxa_count
    score = case taxa
            when 0
              0 # No taxa = irrelvant. Really, you shouldn't get here.
            when 1
              100
            when 2..4
              100 - (taxa * 4)
            when 5..300
              (80 / (taxa / 4.0)).to_i
            else
              0 # Way too big.
            end
    return 0 if score <= 0
    return 100 if score >= 100
    return score.to_i
  end

  def calculate_item_relevance
    items = collection.collection_items.count
    annotated = collection.collection_items.annotated.count
    item_score = case items
                 when 0..100
                   items
                 else
                   100
                 end
    percent_annotated = annotated <= 0 ? 0 : (items / annotated.to_f)
    score = ((item_score / 2) + (percent_annotated / 2)).to_i
    return 0 if score <= 0
    return 100 if score >= 100
    return score.to_i
  end

  def count_containing_collections(opts = {})
    if opts[:is_featured] === true
      extra_condition = "AND com.id IS NOT NULL"
    elsif opts[:is_featured] === false
      extra_condition = "AND com.id IS NULL"
    end
      
    Collection.connection.execute(%(
      SELECT COUNT(DISTINCT(c.id))
      FROM collections c
      JOIN collection_items ci ON ( c.id = ci.collection_id )
      LEFT JOIN (
        collections_communities cc
        JOIN communities com ON ( cc.community_id = com.id )
      ) ON ( c.id = cc.collection_id )
      WHERE ( ci.collected_item_id = #{collection.id}
        AND ci.collected_item_type = 'Collection') #{extra_condition})).first.first
  end

end
