require 'eol/activity_loggable'

class Collection < ActiveRecord::Base

  include EOL::ActivityLoggable

  REINDEX_LIMIT = 30_000

  belongs_to :user # This is the OWNER.  Use #users rather than #user... this basically only gets set once.
  belongs_to :sort_style
  belongs_to :view_style

  has_many :collection_items
  has_many :others_collection_items, class_name: CollectionItem.to_s, as: :collected_item
  has_many :containing_collections, through: :others_collection_items, source: :collection

  has_many :comments, as: :parent

  has_one :resource
  has_one :resource_preview, class_name: Resource.to_s, foreign_key: :preview_collection_id

  has_and_belongs_to_many :communities, uniq: true
  has_and_belongs_to_many :users
  has_and_belongs_to_many :collection_jobs

  attr_accessible :name, :collection_items_attributes, :description, :users,
  :view_style, :published, :special_collection_id, :show_references,
  :sort_style_id, :view_style_id, :collection_items_count, :logo,
  :logo_cache_url, :logo_content_type, :logo_file_name, :logo_file_size

  accepts_nested_attributes_for :collection_items

  scope :published, -> { where(published: true) }
  scope :non_watch, -> { where(
    "special_collection_id != #{SpecialCollection.watch.id}") }
  scope :watch, -> { where(special_collection_id: SpecialCollection.watch.id) }

  # JRice removed the requirement for the uniqueness of the name. Why? Imagine
  # user#1 creates a collection named "foo". She then gives user#2 acess to
  # "foo".  user#2 already has a collection called "foo", but this collection is
  # never saved, so there is no error thrown (and if there were, what would it
  # say?).  User#2 then tries to add an icon to the new "foo", but it fails
  # because the name of the collection is already taken in the scope of all of
  # its users. ...What would the message say, and why would she care? I don't
  # see any of these messages as clear... or helpful. ...more trouble than it's
  # worth, and the restriction is fairly arbitrary anyway: it's just there for
  # the clarity of the user.  Now the user needs to manage this by themselves.
  validates_presence_of :name

  before_update :set_relevance_if_collection_items_changed

  include EOL::Logos

  index_with_solr keywords: [ :name ], fulltexts: [ :description ]

  alias :items :collection_items
  alias_attribute :summary_name, :name
  alias_attribute :collected_name, :name

  def self.which_contain(what)
    Collection.joins(:collection_items).where(collection_items: { collected_item_type: what.class.name,
                                              collected_item_id: what.id}).uniq
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

  def clear
    CollectionItem.where(collection_id: id).delete_all
    collection_items_count = 0
    save
    solr = SolrCore::CollectionItems.new
    solr.delete("collection_id:#{id}")
  end

  # NOTE: you don't want to do this unless you REALLY know what you are doing.
  def scrub!
    clear
    name = "Violation of TOS removed"
    description = ""
    save
    solr = SolrCore::SiteSearch.new
    solr.delete_item(self)
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

  # Note: this is stupid, TODO - we CANNOT load the data for all the taxa in the
  # collection! That's *absurd*. (That's what it was doing). We'll need to find
  # another way. Maybe just a DataPointUri.where(taxon_concept_id:
  # collection_items.taxa.map(&:id).count > 0, but I don't want to try that
  # right now). So I'm just seeing whether there are taxa at all:
  def collection_has_data?
    collection_items.taxa.count > 0
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
    # TODO - we aren't really using this ATM, *plus* I think we can duck-type it to #summary_name if we *do* start using it...
    name = case what
      when TaxonConcept
        what.title
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
                                                                    klass: what.class.name))
      end
    collection_items << item = CollectionItem.create(collected_item: what, name: name, collection: self, added_by_user: opts[:user])
    item # Convenience.  Allows us to know the collection_item created and possibly chain it.
  end

  def taxa
    collection_items.taxa
  end

  def taxa_count
    taxa.count
  end

  def maintained_by
    (users + communities).compact.uniq
  end

  # This will return users.
  def managers
    (users + communities.map {|com| com.managers_as_users }).flatten.compact.uniq
  end

  def select_item(item)
    return false unless item
    # find the first collected_item in their collection matching the given item
    found = CollectionItem.find(:first,
      conditions: "collection_id = #{self.id} and collected_item_type = '#{item.class.name}' and collected_item_id = #{item.id}")
    return found if found
    if item.class == DataObject
      # for data objects we can further check for any item in the collection with the same guid
      found = CollectionItem.find(:first,
        conditions: "collection_id = #{self.id} and collected_item_type = '#{item.class.name}' and do_guid.id = #{item.id}",
        joins: 'JOIN data_objects do ON (collection_items.collected_item_id=do.id) JOIN data_objects do_guid ON (do.guid=do_guid.guid)')
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
    sort_by_style = options[:sort_by].blank? ? sort_style_or_default : SortStyle.find(options[:sort_by])
    items = begin
              EOL::Solr::CollectionItems.search_with_pagination(self.id, options.merge(sort_by: sort_by_style))
            rescue ActiveRecord::RecordNotFound
              logger.error "** ERROR: Collection #{id} failed to find all items... reindexing."
              EOL::Solr::CollectionItemsCoreRebuilder.reindex_collection(self)
              EOL::Solr::CollectionItems.search_with_pagination(self.id, options.merge(sort_by: sort_by_style))
            end
  end

  def facet_count(type)
    EOL::Solr::CollectionItems.get_facet_counts(self.id)[type]
  end

  def facet_counts
    EOL::Solr::CollectionItems.get_facet_counts(self.id)
  end

  def watch_collection?
    special_collection_id && special_collection_id == SpecialCollection.watch.id
  end

  # This is somewhat expensive (can take a second to run), so use sparringly.
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
    others_collection_items.includes({ collection: :communities }).collect do |ci|
      ci.collection ? ci.collection.communities.select{ |com| com.published? } : nil
    end.flatten.compact.uniq
  end

  def fix_item_count
    update_attributes(collection_items_count: collection_items.count)
  end

  def unpublish
    if update_attributes(published: false)
      EOL::GlobalStatistics.decrement('collections')
      remove_from_index
      true
    else
      false
    end
  end

  def can_be_updated_by?(user_wanting_access)
    user_wanting_access.can_edit_collection?(self)
  end

  def can_be_deleted_by?(user_wanting_access)
    self.users.map{|u| u.id}.include? user_wanting_access.id || user_wanting_access.is_admin?
  end

  def as_json(options = {})
    collection = super(
      options.merge(
        except: [:logo_cache_url, :logo_content_type, :logo_file_name,
          :logo_file_size, :published, :special_collection_id],
      )
    ).merge(logo_path: logo_url)
    collection.merge!(collection_items: collection_items) if options[:items]
    collection
  end

private

  def set_relevance_if_collection_items_changed
    set_relevance if collection_items && collection_items.last && collection_items.last.changed?
  end

end
