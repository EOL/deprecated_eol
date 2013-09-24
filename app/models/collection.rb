require 'eol/activity_loggable'

class Collection < ActiveRecord::Base

  include EOL::ActivityLoggable

  belongs_to :user # This is the OWNER.  Use #users rather than #user... this basically only gets set once.
  belongs_to :sort_style
  belongs_to :view_style

  has_many :collection_items
  has_many :others_collection_items, :class_name => CollectionItem.to_s, :as => :collected_item
  has_many :containing_collections, :through => :others_collection_items, :source => :collection

  has_many :comments, :as => :parent

  has_one :resource
  has_one :resource_preview, :class_name => Resource.to_s, :foreign_key => :preview_collection_id

  has_and_belongs_to_many :communities, :uniq => true
  has_and_belongs_to_many :users
  has_and_belongs_to_many :collection_jobs

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

  has_attached_file :logo,
    :path => $LOGO_UPLOAD_DIRECTORY,
    :url => $LOGO_UPLOAD_PATH,
    :default_url => "/assets/blank.gif"
  
  validates_attachment_content_type :logo,
    :content_type => ['image/pjpeg','image/jpeg','image/png','image/gif', 'image/x-png'],
    :if => Proc.new { |s| s.class.column_names.include?('logo_file_name') }
  validates_attachment_size :logo, :in => 0..$LOGO_UPLOAD_MAX_SIZE,
    :if => Proc.new { |s| s.class.column_names.include?('logo_file_name') }


  index_with_solr :keywords => [ :name ], :fulltexts => [ :description ]

  alias :items :collection_items
  alias_attribute :summary_name, :name
  alias_attribute :collected_name, :name

  def self.which_contain(what)
    Collection.joins(:collection_items).where(:collection_items => { :collected_item_type => what.class.name,
                                              :collected_item_id => what.id}).uniq
  end

  def self.get_taxa_counts(collections)
    collection_ids = collections.map(&:id).join(',')
    return if collection_ids.empty?
    collections_with_counts = Collection.find_by_sql("
      SELECT c.id, count(*) as count
      FROM collections c JOIN collection_items ci ON (c.id = ci.collection_id AND ci.collected_item_type = 'TaxonConcept')
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

  def add(what, opts = {})
    return if what.nil?
    name = case what
      when TaxonConcept
        what.scientific_name
      when User
        what.full_name
      when DataObject
        what.short_title
      when Community
        what.name
      when Collection
        what.name
      else
        raise EOL::Exceptions::InvalidCollectionItemType.new(I18n.t(:cannot_create_collection_item_from_class_error,
                                                                    :klass => what.class.name))
      end
    collection_items << item = CollectionItem.create(:collected_item => what, :name => name, :collection => self, :added_by_user => opts[:user])
    set_relevance
    item # Convenience.  Allows us to know the collection_item created and possibly chain it.
  end

  def logo_url(size = 'large', specified_content_host = nil)
    if logo_cache_url.blank?
      return "v2/logos/collection_default.png"
    elsif size.to_s == 'small'
      DataObject.image_cache_path(logo_cache_url, '88_88', :specified_content_host => specified_content_host)
    else
      DataObject.image_cache_path(logo_cache_url, '130_130', :specified_content_host => specified_content_host)
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

  def select_item(item)
    return false unless item
    # find the first collected_item in their collection matching the given item
    found = CollectionItem.find(:first,
      :conditions => "collection_id = #{self.id} and collected_item_type = '#{item.class.name}' and collected_item_id = #{item.id}")
    return found if found
    if item.class == DataObject
      # for data objects we can further check for any item in the collection with the same guid
      found = CollectionItem.find(:first,
        :conditions => "collection_id = #{self.id} and collected_item_type = '#{item.class.name}' and do_guid.id = #{item.id}",
        :joins => 'JOIN data_objects do ON (collection_items.collected_item_id=do.id) JOIN data_objects do_guid ON (do.guid=do_guid.guid)')
      return found if found
    end
    nil
  end

  def has_item?(item)
    return false unless item
    return true if select_item(item)
  end

  def view_style_or_default
    view_style ? view_style : ViewStyle.annotated
  end

  def sort_style_or_default
    sort_style ? sort_style : SortStyle.newest
  end

  def items_from_solr(options={})
    sort_by_style = SortStyle.find(options[:sort_by].blank? ? sort_style_or_default : options[:sort_by])
    items = begin
              EOL::Solr::CollectionItems.search_with_pagination(self.id, options.merge(:sort_by => sort_by_style))
            rescue ActiveRecord::RecordNotFound
              logger.error "** ERROR: Collection #{id} failed to find all items... reindexing."
              EOL::Solr::CollectionItemsCoreRebuilder.reindex_collection(self)
              EOL::Solr::CollectionItems.search_with_pagination(self.id, options.merge(:sort_by => sort_by_style))
            end
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
    Resque.enqueue(CollectionRelevanceCalculator, id)
  end
  
  def can_be_read_by?(user)
    return true if published? || users.include?(user) || user.is_admin?
    false
  end

  def to_s
    "Collection ##{id}: #{name}"
  end

  def inaturalist_project_info
    InaturalistProjectInfo.get(id)
  end
  
  def featuring_communities
    others_collection_items.includes({ :collection => :communities }).collect do |ci|
      ci.collection ? ci.collection.communities.select{ |com| com.published? } : nil
    end.flatten.compact.uniq
  end

  def unpublish
    if update_attributes(:published => false)
      EOL::GlobalStatistics.decrement('collections')
      true
    else 
      false
    end
  end

private

  def set_relevance_if_collection_items_changed
    set_relevance if collection_items && collection_items.last && collection_items.last.changed?
  end

end
