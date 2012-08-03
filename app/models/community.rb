require 'eol/activity_loggable'

class Community < ActiveRecord::Base

  include EOL::ActivityLoggable

  has_and_belongs_to_many :collections, :uniq => true

  has_many :members
  has_many :users, :through => :members
  has_many :collection_items, :as => :object # THIS IS COLLECTION ITEMS POINTING AT THIS COLLECTION!
  has_many :collected_items, :class_name => 'CollectionItem',
           :finder_sql => 'SELECT ci.* FROM collection_items ci JOIN collections c ON (ci.collection_id = c.id) ' +
             'JOIN collections_communities cc ON (cc.collection_id = c.id) WHERE cc.community_id = #{self.id}'
  has_many :containing_collections, :through => :collection_items, :source => :collection
  has_many :comments, :as => :parent

  named_scope :published, :conditions => 'published = 1'

  # These are for will_paginate:
  cattr_reader :per_page
  @@per_page = 30

  validates_presence_of :name, :message => I18n.t(:cannot_be_empty)
  validates_length_of :name, :maximum => 127, :message => I18n.t(:must_be_less_than_128_characters_long)
  validates_uniqueness_of :name, :message => I18n.t(:has_already_been_taken), :if => Proc.new {|c| c.published? }

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

  alias :focuses :collections
  alias_attribute :summary_name, :name

  # Don't get dizzy.  This is all of the collections this community has collected.  This is the same thing as
  # "featured" collections or "endorsed" collections... that is the way it's done, now: you simply add the collection
  # to the community's focus.
  #
  # NOTE that this returns the collection_item, NOT the collection it points to!  This is so you can get the
  # annotation along with it.
  def featured_collections
    return [] unless self.collections && !self.collections.blank?
    collected_items.select{ |ci| ci.object_type == 'Collection' }
  end

  # TODO - test
  # Auto-joins the user to the community, and makes that person the owner.
  def initialize_as_created_by(user)
    mem = add_member(user)
    mem.update_attributes(:manager => true)
    mem
  end

  # Returns the new member.
  def add_member(user, opts = {})
    member = Member.create!(:user_id => user.id, :community_id => id)
    members << member
    member
  end

  def remove_member(user_or_member)
    member = user_or_member.is_a?(User) ?
      Member.find_by_user_id_and_community_id(user_or_member.id, id) :
      user_or_member
    raise EOL::Exceptions::ObjectNotFound unless member
    member.destroy
    self.members.delete(member)
  end

  # Careful!  This doesn't mean a given USER can edit the collection, just that managers of this community can.
  # This is required because of the duck typing in app/views/collections/_choose_editor_target.html.haml
  def can_edit_collection?(collection)
    collection.communities.include?(self) # Her collection
  end

  def has_member?(user)
    members.map {|m| m.user_id}.include?(user.id)
  end

  def logo_url(size = 'large', specified_content_host = nil)
    if logo_cache_url.blank?
      return "v2/logos/community_default.png"
    elsif size.to_s == 'small'
      DataObject.image_cache_path(logo_cache_url, '88_88', specified_content_host)
    else
      DataObject.image_cache_path(logo_cache_url, '130_130', specified_content_host)
    end
  end

  def top_active_members
    activity_log.map {|l|
      l['user_id']
    }.compact.sort.uniq.map {|uid|
      Member.find_by_community_id_and_user_id(id, uid)
    }.compact[0..3]
  end
  
  def cached_count_members
    Rails.cache.fetch("communities/cached_count_members/#{self.id}", :expires_in => 10.minutes) do
      members.count
    end
  end

  def managers_as_users
    members.managers.map {|m| m.user }
  end

  def is_curator_community?
    self.id == CuratorCommunity.get.id
  end

end
