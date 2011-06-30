class Collection < ActiveRecord::Base

  belongs_to :user
  belongs_to :community # These are focus lists

  has_many :collection_endorsements
  has_many :collection_items
  alias :items :collection_items
  has_many :communities, :through => CollectionEndorsement # NOTE: be sure to check each for actually being endorsed!

  # TODO = you can have collections that point to collections, so there SHOULD be a has_many relationship here to all of the
  # collection items that contain this collection.  ...I don't know if we need that yet, but it would normally be named
  # "collection_items", which doesn't work (because we're using that for THIS collection's children)... so we will have to
  # re-name it and make it slightly clever.

  validates_presence_of :name

  # This is cheating, slightly.  We want it to be unique within a user's scope, but ALSO within the scope of ALL
  # communities... it so happens that the scope of the later is, in fact, a user_id (of nil)... so this works:
  validates_uniqueness_of :name, :scope => [:user_id]
  validates_uniqueness_of :community_id, :if => Proc.new {|l| ! l.community_id.blank? }

  index_with_solr :keywords => [:name]

  def editable_by?(user)
    return false if special_collection_id # None of the special lists may be edited.
    if user_id
      return user.id == user_id # Owned by this user?
    else
      return user.member_of(community).can?(Privilege.edit_collections)
    end
  end

  def is_focus_list?
    community_id
  end

  def add(what, opts = {})
    name = "something"
    opts[:user] ||= user
    raise "No user specified" if opts[:user].nil?
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
    CollectionActivityLog.create(:collection => self, :collection_item => collection_items.last,
                                 :user => opts[:user], :activity => Activity.collect)
    what # Convenience.  Allows us to chain this command and continue using the object passed in.
  end

  def create_community
    raise EOL::Exceptions::OnlyUsersCanCreateCommunitiesFromCollections unless user
    community = Community.create(:name => "#{name} Community")
    community.initialize_as_created_by(user)
    # Deep copy:
    collection_items.each do |li|
      community.focus.add(li.object, :user => user)
    end
    community
  end

  def logo_url(size = 'large')
    logo_cache_url.blank? ? "v2/logos/empty_collection.png" : ContentServer.agent_logo_path(logo_cache_url, size)
  end

  def taxa
    collection_items.collect{|ci| ci if ci.object_type == 'TaxonConcept'}
  end

  def filter_type(type)
    #needs this to properly assign values from collection_items.object_type
    if type == 'taxa'
      type = 'TaxonConcept'
    elsif type == 'communities'
      type = 'Community'
    elsif type == 'people'
      type = 'User'
    elsif type == 'collections'
      type = 'Collection'
    end

    data_type_ids = nil
    if type == "images"
      data_type_ids = DataType.image_type_ids
    elsif type == "videos"
      data_type_ids = DataType.video_type_ids
    elsif type == "sounds"
      data_type_ids = DataType.sound_type_ids
    elsif type == "articles"
      data_type_ids = DataType.text_type_ids
    end

    if data_type_ids
      collection_items.collect{|ci| ci if (ci.object_type == 'DataObject') && (data_type_ids.include? ci.object.data_type_id)}
    else
      collection_items.collect{|ci| ci if ci.object_type == type}
    end
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

private

  def validate
    errors.add(:user_id, I18n.t(:must_be_associated_with_either_a_user_or_a_community) ) if
      self.community_id.nil? && self.user_id.nil?
    errors.add(:user_id, I18n.t(:cannot_be_associated_with_both_a_user_and_a_community) ) if
      ((! self.community_id.nil?) && (! self.user_id.nil?))
  end

end
