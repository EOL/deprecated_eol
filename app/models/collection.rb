require 'eol/activity_loggable'

class Collection < ActiveRecord::Base

  include EOL::ActivityLoggable

  belongs_to :user # This is the OWNER.  Use #users rather than #user... this basically only gets set once.
  belongs_to :sort_style
  belongs_to :view_style

  has_many :collection_items
  accepts_nested_attributes_for :collection_items
  has_many :others_collection_items, :class_name => CollectionItem.to_s, :as => :object
  has_many :containing_collections, :through => :others_collection_items, :source => :collection

  has_many :comments, :as => :parent

  has_one :resource
  has_one :resource_preview, :class_name => Resource.to_s, :foreign_key => :preview_collection_id

  has_and_belongs_to_many :communities, :uniq => true
  has_and_belongs_to_many :users

  scope :published, :conditions => {:published => 1}
  # NOTE - I'm actually not sure why the lambda needs TWO braces, but the exmaple I was copying used two, soooo...
  scope :watch, lambda { { :conditions => {:special_collection_id => SpecialCollection.watch.id} } }

  validates_presence_of :name
  # JRice removed the requirement for the uniqueness of the name. Why? Imagine user#1 creates a collection named "foo".
  # She then gives user#2 acess to "foo".  user#2 already has a collection called "foo", but this collection is never
  # saved, so there is no error thrown (and if there were, what would it say?).  User#2 then tries to add an icon to
  # the new "foo", but it fails because the name of the collection is already taken in the scope of all of its users.
  # ...What would the message say, and why would she care? I don't see any of these messages as clear... or helpful.
  # ...more trouble than it's worth, and the restriction is fairly arbitrary anyway: it's just there for the clarity
  # of the user.  Now the user needs to manage this by themselves.

  before_update :set_relevance_if_collection_items_changed

  # has_attached_file :logo,
  #   :path => $LOGO_UPLOAD_DIRECTORY,
  #   :url => $LOGO_UPLOAD_PATH,
  #   :default_url => "/assets/blank.gif"
  # 
  # validates_attachment_content_type :logo,
  #   :content_type => ['image/pjpeg','image/jpeg','image/png','image/gif', 'image/x-png']
  # validates_attachment_size :logo, :in => 0..$LOGO_UPLOAD_MAX_SIZE

  index_with_solr :keywords => [ :name ], :fulltexts => [ :description ]

  alias :items :collection_items
  alias_attribute :summary_name, :name

  def self.which_contain(what)
    Collection.joins(:collection_items).where(:collection_items => { :object_type => what.class.name, :object_id =>
                                              what.id}).uniq
  end

  def self.get_taxa_counts(collections)
    collection_ids = collections.map(&:id).join(',')
    return if collection_ids.empty?
    collections_with_counts = Collection.find_by_sql("
      SELECT c.id, count(*) as count
      FROM collections c JOIN collection_items ci ON (c.id = ci.collection_id AND ci.object_type = 'TaxonConcept')
      WHERE c.id IN (#{collection_ids})
      GROUP BY c.id")
    taxa_counts = {}
    collections_with_counts.each do |cwc|
      if c = collections.detect{ |c| c.id == cwc.id }
        taxa_counts[c.id] = cwc['count'].to_i
      end
    end
    return taxa_counts
  end

  def special?
    return true if special_collection_id
    communities.each do |community|
      return true if community.collections.count == 1 # It's special if any of its communities has ONLY this collection
    end
    return false
  end

  def editable_by?(whom)
    whom.can_edit_collection?(self)
  end

  def is_resource_collection?
    return true if resource || resource_preview
  end

  def focus?
    communities.count > 0 # Assuming #count is faster than not.
  end
  alias :is_focus_list? :focus?

  # NOTE - DO NOT (!) use this method in bulk... take advantage of the accepts_nested_attributes_for if you want to
  # add more than two things... because this runs an expensive calculation at the end.
  # 
  # Also NOTE that we don't just use { :object => what }, because Users are sometimes Curators... there may be other
  # reasons, but that was at least true, so I kept the other creates consistent.
  def add(what, opts = {})
    return if what.nil?
    name = "something"
    case what.class.name
    when "TaxonConcept"
      collection_items << CollectionItem.create(:object_type => "TaxonConcept", :object_id => what.id, :name => what.scientific_name, :collection => self, :added_by_user => opts[:user])
      name = what.scientific_name
    when "User"
      collection_items << CollectionItem.create(:object_type => "User", :object_id => what.id, :name => what.full_name, :collection => self, :added_by_user => opts[:user])
      name = what.username
    when "DataObject"
      collection_items << CollectionItem.create(:object_type => "DataObject", :object_id => what.id, :name => what.short_title, :collection => self, :added_by_user => opts[:user])
      name = what.data_type.simple_type('en')
    when "Community"
      collection_items << CollectionItem.create(:object_type => "Community", :object_id => what.id, :name => what.name, :collection => self, :added_by_user => opts[:user])
      name = what.name
    when "Collection"
      collection_items << CollectionItem.create(:object_type => "Collection", :object_id => what.id, :name => what.name, :collection => self, :added_by_user => opts[:user])
      name = what.name
    else
      raise EOL::Exceptions::InvalidCollectionItemType.new(I18n.t(:cannot_create_collection_item_from_class_error,
                                                                  :klass => what.class.name))
    end
    set_relevance # This is actually safe, because we don't use #add in bulk.
    what # Convenience.  Allows us to chain this command and continue using the object passed in.
  end

  def logo_url(size = 'large', specified_content_host = nil)
    if logo_cache_url.blank?
      return "v2/logos/collection_default.png"
    elsif size.to_s == 'small'
      DataObject.image_cache_path(logo_cache_url, '88_88', specified_content_host)
    else
      DataObject.image_cache_path(logo_cache_url, '130_130', specified_content_host)
    end
  end

  def taxa
    collection_items.taxa
  end

  def maintained_by
    (users + communities).compact
  end

  # This will return users.
  def managers
    (users + communities.map {|com| com.managers_as_users }).flatten.compact.uniq
  end

  def has_item?(item)
    return false unless item
    # find the first object in their collection matching the given item
    return true if CollectionItem.find(:first,
      :conditions => "collection_id = #{self.id} and object_type = '#{item.class.name}' and object_id = #{item.id}")
    if item.class == DataObject
      # for data objects we can further check for any item in the collection with the same guid
      return true if CollectionItem.find(:first,
        :conditions => "collection_id = #{self.id} and object_type = '#{item.class.name}' and do_guid.id = #{item.id}",
        :joins => 'JOIN data_objects do ON (collection_items.object_id=do.id) JOIN data_objects do_guid ON (do.guid=do_guid.guid)')
    end
  end

  # TODO - This does NOT belong here.  It belongs on ViewStyle (as a class method).  Fix.
  def default_view_style
    view_style ? view_style : ViewStyle.annotated
  end

  def default_sort_style
    sort_style ? sort_style : SortStyle.newest
  end

  def items_from_solr(options={})
    sort_by_style = SortStyle.find(options[:sort_by].blank? ? default_sort_style : options[:sort_by])
    EOL::Solr::CollectionItems.search_with_pagination(self.id, options.merge(:sort_by => sort_by_style))
  end

  def facet_count(type)
    EOL::Solr::CollectionItems.get_facet_counts(self.id)[type]
  end

  def facet_counts
    EOL::Solr::CollectionItems.get_facet_counts(self.id)
  end

  def cached_count
    Rails.cache.fetch("collections/cached_count/#{self.id}", :expires_in => 10.minutes) do
      collection_items.count
    end
  end

  def watch_collection?
    special_collection_id && special_collection_id == SpecialCollection.watch.id
  end

  def set_relevance
    # TODO - this occasionally seems to make Paperclip quite grumpy, but only in tests.  Hmmmn.
    update_attributes(:relevance => calculate_relevance)
  end
  
  def count_containing_collections(opts = {})
    if opts[:is_featured] === true
      extra_condition = "AND com.id IS NOT NULL"
    elsif opts[:is_featured] === false
      extra_condition = "AND com.id IS NULL"
    end
      
    count_result = connection.execute("
      SELECT COUNT(DISTINCT(c.id))
      FROM collections c
      JOIN collection_items ci ON ( c.id = ci.collection_id )
      LEFT JOIN (
        collections_communities cc
        JOIN communities com ON ( cc.community_id = com.id )
      ) ON ( c.id = cc.collection_id )
      WHERE ( ci.object_id = #{self.id} AND ci.object_type = 'Collection') #{extra_condition}")
    count_result.first.first
  end

  def can_be_read_by?(user)
    return true if published? || users.include?(user) || user.is_admin?
    false
  end

  def to_s
    "Collection ##{id}: #{name}"
  end

  # TODO - we should only call this when the collection is "known" to be iNat-enabled, even if this is denormalized
  # information.  As-is, we're pinging iNat every time we load a collection page, which is too often.
  def inaturalist_project_info
    # TODO - move this to an environment variable:
    url = "http://www.inaturalist.org/projects.json?source=http://eol.org/collections/#{id}"
    begin
      response = Net::HTTP.get(URI.parse(url)) # TODO - add a VERY SHORT timeout, here.
      JSON.parse(response)[0]
    rescue => e
      nil
    end
  end
  
  def featuring_communities
    others_collection_items.collect do |ci|
      ci.collection ? ci.collection.communities.where('published = 1') : nil
    end.flatten.compact.uniq
  end

private

  # This should set the relevance attribute score between 0 and 100.  Use this sparringly, it's expensive to calculate:
  def calculate_relevance
    return 0 if watch_collection? # Watch collections are irrelevant.
    @taxa_count = collection_items.taxa.count
    return 0 if @taxa_count <= 0 # Collections with no taxa (ie: friend lists and the like) are irrelevant.
    # Each sub-category should return a score between 1 and 100:
    score = (calculate_feature_relevance * 0.4) + (calculate_taxa_relevance * 0.4) + (calculate_item_relevance * 0.2)
    return 0 if score <= 0
    return 100 if score >= 100
    score.to_i
  end

  def calculate_feature_relevance
    features = count_containing_collections(:is_featured => true)
    times_featured_score = case features
                           when 0
                             0
                           when 1..25
                             2 * features
                           else
                             50
                           end
    collected = count_containing_collections(:is_featured => false)
    times_collected_score = case collected
                            when 0
                              0
                            when 1..30
                              collected
                            else
                              30
                            end
    is_focus_list_score = focus? ? 20 : 0
    score = times_featured_score + times_collected_score + is_focus_list_score
    return 0 if score <= 0
    return 100 if score >= 100
    return score.to_i
  end

  # Extremely focused list = high score ... too many taxa = not as relevant.
  def calculate_taxa_relevance
    taxa = @taxa_count || collection_items.taxa.count
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
    items = collection_items.count
    annotated = collection_items.annotated.count
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

  def set_relevance_if_collection_items_changed
    relevance = calculate_relevance if collection_items && collection_items.last && collection_items.last.changed?
  end

end
