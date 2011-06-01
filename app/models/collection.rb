class Collection < ActiveRecord::Base

  belongs_to :user
  belongs_to :community # These are focus lists

  has_many :collection_items
  alias :items :collection_items

  # TODO = you can have collections that point to collections, so there SHOULD be a has_many relationship here to all of the
  # collection items that contain this collection.  ...I don't know if we need that yet, but it would normally be named
  # "collection_items", which doesn't work (because we're using that for THIS collection's children)... so we will have to
  # re-name it and make it slightly clever.

  validates_presence_of :name

  # This is cheating, slightly.  We want it to be unique within a user's scope, but ALSO within the scope of ALL
  # communities... it so happens that the scope of the later is, in fact, a user_id (of nil)... so this works:
  validates_uniqueness_of :name, :scope => [:user_id]
  validates_uniqueness_of :community_id, :if => Proc.new {|l| ! l.community_id.blank? }

  def editable_by?(user)
    return false if special_collection_id # None of the special lists may be edited.
    if user_id
      return user.id == user_id # Owned by this user?
    else
      return user.member_of(community).can?(Privilege.edit_community)
    end
  end

  def is_focus_list?
    community_id
  end

  def add(what)
    name = "something"
    case what.class.name
    when "TaxonConcept"
      collection_items << CollectionItem.create(:object_type => "TaxonConcept", :object_id => what.id, :name => what.scientific_name)
      name = what.scientific_name
    when "User"
      collection_items << CollectionItem.create(:object_type => "User", :object_id => what.id, :name => what.full_name)
      name = what.username
    when "DataObject"
      collection_items << CollectionItem.create(:object_type => "DataObject", :object_id => what.id, :name => what.short_title)
      name = what.data_type.simple_type
    when "Community"
      collection_items << CollectionItem.create(:object_type => "Community", :object_id => what.id, :name => what.name)
      name = what.name
    when "Collection"
      collection_items << CollectionItem.create(:object_type => "Collection", :object_id => what.id, :name => what.name)
      name = what.name
    else
      raise EOL::Exceptions::InvalidCollectionItemType.new("I cannot create a collection item from a #{what.class.name}")
    end
    if is_focus_list?
      community.feed.post(I18n.t("community_watching_this_note", :name => name), :feed_item_type_id => FeedItemType.content_update.id, :subject_id => what.id, :subject_type => what.class.name)
    end
    what # Convenience.  Allows us to chain this command and continue using the object passed in.
  end

  def create_community
    raise EOL::Exceptions::OnlyUsersCanCreateCommunitiesFromCollections unless user
    community = Community.create(:name => "#{name} Community")
    community.initialize_as_created_by(user)
    # Deep copy:
    collection_items.each do |li|
      community.focus.add(li.object)
    end
    community
  end
  
  def logo_url(size = 'large')
    logo_cache_url.blank? ? "v2/logos/empty_collection.png" : ContentServer.agent_logo_path(logo_cache_url, size)
  end

private

  def validate
    errors.add(:user_id, I18n.t(:must_be_associated_with_either_a_user_or_a_community) ) if
      self.community_id.nil? && self.user_id.nil?
    errors.add(:user_id, I18n.t(:cannot_be_associated_with_both_a_user_and_a_community) ) if
      ((! self.community_id.nil?) && (! self.user_id.nil?))
  end

end
