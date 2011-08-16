class Collection < ActiveRecord::Base

  include EOL::ActivityLoggable

  belongs_to :user
  belongs_to :community # These are focus lists
  belongs_to :sort_style

  has_many :collection_items
  accepts_nested_attributes_for :collection_items
  has_many :others_collection_items, :class_name => CollectionItem.to_s, :as => :object
  has_many :containing_collections, :through => :others_collection_items, :source => :collection

  has_many :comments, :as => :parent
  # NOTE - You MUST use single-quotes here, lest the #{id} be interpolated at compile time. USE SINGLE QUOTES.
  # this will return the communities which have collected this collection. Those communities 'feature' this collection
  has_many :communities,
    :finder_sql => 'SELECT cm.* FROM communities cm, collections c, collection_items ci ' +
      'WHERE ci.object_type = "Collection" AND ci.object_id = #{id} ' +
      'AND ci.collection_id = c.id AND c.community_id = cm.id AND cm.published = 1'

  has_one :resource
  has_one :resource_preview, :class_name => Resource.to_s, :foreign_key => :preview_collection_id

  # TODO = you can have collections that point to collections, so there SHOULD be a has_many relationship here to all
  # of the collection items that contain this collection.  ...I don't know if we need that yet, but it would normally
  # be named "collection_items", which doesn't work (because we're using that for THIS collection's children)... so
  # we will have to re-name it and make it slightly clever.

  validates_presence_of :name

  validates_uniqueness_of :name, :scope => [:user_id]
  validates_uniqueness_of :community_id, :if => Proc.new {|l| ! l.community_id.blank? }

  # TODO: remove the :if condition after migrations are run in production
  has_attached_file :logo,
    :path => $LOGO_UPLOAD_DIRECTORY,
    :url => $LOGO_UPLOAD_PATH,
    :default_url => "/images/blank.gif",
    :if => self.column_names.include?('logo_file_name')

  validates_attachment_content_type :logo,
    :content_type => ['image/pjpeg','image/jpeg','image/png','image/gif', 'image/x-png'],
    :if => self.column_names.include?('logo_file_name')
  validates_attachment_size :logo, :in => 0..$LOGO_UPLOAD_MAX_SIZE,
    :if => self.column_names.include?('logo_file_name')

  index_with_solr :keywords => [ :name ], :fulltexts => [ :description ]

  define_core_relationships :select => '*'

  alias :items :collection_items
  alias_attribute :summary_name, :name

  def self.which_contain(what)
    Collection.find(:all, :joins => :collection_items, :conditions => "collection_items.object_type='#{what.class.name}' and collection_items.object_id=#{what.id}").uniq
  end

  # this method will quickly get the counts for multiple collections at the same time
  def self.add_counts!(collections)
    collection_ids = collections.collect{ |c| c.id }.join(',')
    return if collection_ids.empty?
    collections_with_counts = Collection.find_by_sql("
      SELECT c.*, count(*) as count
      FROM collections c JOIN collection_items ci ON (c.id=ci.collection_id)
      WHERE c.id IN (#{collection_ids})
      GROUP BY c.id")
    collections_with_counts.each do |cwc|
      if c = collections.detect{ |c| c.id }
        c['collection_items_count'] = cwc['count'].to_i
      end
    end
  end

  def self.add_taxa_counts!(collections)
    collection_ids = collections.collect{ |c| c.id }.join(',')
    return if collection_ids.empty?
    collections_with_counts = Collection.find_by_sql("
      SELECT c.*, count(*) as count
      FROM collections c JOIN collection_items ci ON (c.id=ci.collection_id)
      WHERE c.id IN (#{collection_ids})
      AND ci.object_type = 'TaxonConcept'
      GROUP BY c.id")
    collections_with_counts.each do |cwc|
      if c = collections.detect{ |c| c.id }
        c['taxa_count'] = cwc['count'].to_i
      end
    end
  end

  def self.sort_for_overview(collections)
    col = collections.sort_by do |c|
      is_collected_by_community = c.community_id? ? 0 : 1 # opposite so those in communities come first
      taxa_count = c['taxa_count'] || 0
      collection_items_count = c['collection_items_count'] || 0
      [ is_collected_by_community,
        taxa_count,
        collection_items_count ]
    end
  end

  def special?
    special_collection_id
  end

  def editable_by?(user)
    if user_id
      return user.id == user_id # Owned by this user?
    else
      return user.member_of(community) && user.member_of(community).manager?
    end
  end

  def is_resource_collection?
    return true if resource || resource_preview
  end

  def is_focus_list?
    community_id
  end

  def add(what, opts = {})
    return if what.nil?
    name = "something"
    case what.class.name
    when "TaxonConcept"
      collection_items << CollectionItem.create(:object_type => "TaxonConcept", :object => what, :name => what.scientific_name, :collection => self, :added_by_user => opts[:user])
      name = what.scientific_name
    when "User"
      collection_items << CollectionItem.create(:object_type => "User", :object => what, :name => what.full_name, :collection => self, :added_by_user => opts[:user])
      name = what.username
    when "DataObject"
      collection_items << CollectionItem.create(:object_type => "DataObject", :object => what, :name => what.short_title, :collection => self, :added_by_user => opts[:user])
      name = what.data_type.simple_type('en')
    when "Community"
      collection_items << CollectionItem.create(:object_type => "Community", :object => what, :name => what.name, :collection => self, :added_by_user => opts[:user])
      name = what.name
    when "Collection"
      collection_items << CollectionItem.create(:object_type => "Collection", :object => what, :name => what.name, :collection => self, :added_by_user => opts[:user])
      name = what.name
    else
      raise EOL::Exceptions::InvalidCollectionItemType.new(I18n.t(:cannot_create_collection_item_from_class_error,
                                                                  :klass => what.class.name))
    end
    collection_items.last.update_attribute(:annotation, opts[:annotation]) if opts[:annotation]
    what # Convenience.  Allows us to chain this command and continue using the object passed in.
  end

  def deep_copy(other)
    copy_annotations = user_id && other.user_id && user_id == other.user_id
    other.collection_items.each do |item|
      if copy_annotations
        add(item.object, :annotation => item.annotation)
      else
        add(item.object)
      end
    end
  end

  def logo_url(size = 'large')
    if logo_cache_url.blank?
      return "v2/logos/empty_collection.png"
    elsif size.to_s == 'small'
      DataObject.image_cache_path(logo_cache_url, '88_88')
    else
      DataObject.image_cache_path(logo_cache_url, '130_130')
    end
  end

  def taxa
    collection_items.collect{|ci| ci if ci.object_type == 'TaxonConcept'}
  end

  def maintained_by
    return user.full_name if !user_id.blank?
    return community.name if !community_id.blank?
  end

  def has_item? item
    collection_items.any?{|ci| ci.object_type == item.class.name && ci.object_id == item.id}
  end

  def default_sort_style
    sort_style ? sort_style : SortStyle.newest
  end

  def items_from_solr(options={})
    sort_by_style = SortStyle.find(options[:sort_by].blank? ? default_sort_style : options[:sort_by])
    EOL::Solr::CollectionItems.search_with_pagination(self.id, options.merge(:sort_by => sort_by_style))
  end

  def facet_counts
    EOL::Solr::CollectionItems.get_facet_counts(self.id)
  end

  def watch_collection?
    special? && user_id
  end

private

  def validate
    errors.add(:user_id, I18n.t(:must_be_associated_with_either_a_user_or_a_community) ) if
      self.community_id.nil? && self.user_id.nil?
    errors.add(:user_id, I18n.t(:cannot_be_associated_with_both_a_user_and_a_community) ) if
      ((! self.community_id.nil?) && (! self.user_id.nil?))
  end

end
