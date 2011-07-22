class Collection < ActiveRecord::Base

  include EOL::ActivityLoggable

  belongs_to :user
  belongs_to :community # These are focus lists
  belongs_to :sort_style

  has_many :collection_items
  accepts_nested_attributes_for :collection_items

  has_many :collection_endorsements
  has_many :comments, :as => :parent
  has_many :communities, :through => CollectionEndorsement

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
  validates_attachment_size :logo, :in => 0..0.5.megabyte,
    :if => self.column_names.include?('logo_file_name')

  index_with_solr :keywords => [ :name ], :fulltexts => [ :description ]

  define_core_relationships :select => '*'

  alias :items :collection_items
  alias_attribute :summary_name, :name

  def special?
    special_collection_id
  end

  def editable_by?(user)
    if user_id
      return user.id == user_id # Owned by this user?
    else
      return user.member_of(community) && user.member_of(community).can?(Privilege.edit_collections)
    end
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
    what # Convenience.  Allows us to chain this command and continue using the object passed in.
  end

  def create_community
    raise EOL::Exceptions::OnlyUsersCanCreateCommunitiesFromCollections unless user
    community = Community.create(:name => I18n.t(:default_community_name_from_collection, :name => name))
    community.initialize_as_created_by(user)
    # Deep copy:
    collection_items.each do |li|
      community.focus.add(li.object, :user => user)
    end
    community
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

  def pending_communities
    collection_endorsements.select {|c| c.pending? }.map {|c| c.community }
  end

  def endorsing_communities
    collection_endorsements.select {|c| c.endorsed? }.map {|c| c.community }
  end

  def request_endorsement_from_community(comm)
    ce = CollectionEndorsement.new
    ce.collection_id = id
    ce.community_id = comm.id
    ce.save!
    ce
  end

  def has_item? item
    collection_items.any?{|ci| ci.object_type == item.class.name && ci.object_id == item.id}
  end

  def default_sort_style
    sort_style ? sort_style : SortStyle.newest
  end

  def items_from_solr(options={})
    sort_by_style = SortStyle.find(options[:sort_by].blank? ? default_sort_style : options[:sort_by])
    EOL::Solr::CollectionItems.search_with_pagination(self.id, :facet_type => options[:facet_type], :page => options[:page], :sort_by => sort_by_style)
  end

  def facet_counts
    EOL::Solr::CollectionItems.get_facet_counts(self.id)
  end

private

  def validate
    errors.add(:user_id, I18n.t(:must_be_associated_with_either_a_user_or_a_community) ) if
      self.community_id.nil? && self.user_id.nil?
    errors.add(:user_id, I18n.t(:cannot_be_associated_with_both_a_user_and_a_community) ) if
      ((! self.community_id.nil?) && (! self.user_id.nil?))
  end

end
