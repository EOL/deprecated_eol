class Community < ActiveRecord::Base

  include EOL::ActivityLoggable

  has_one :collection #TODO - didn't work? , :as => :focus

  has_many :members
  has_many :collection_items, :as => :object
  has_many :containing_collections, :through => :collection_items, :source => :collection
  has_many :comments, :as => :parent

  named_scope :published, :conditions => 'published = 1'

  accepts_nested_attributes_for :collection

  after_create :attatch_focus

  # These are for will_paginate:
  cattr_reader :per_page
  @@per_page = 30

  validates_presence_of :name, :message => I18n.t(:cannot_be_empty)
  validates_length_of :name, :maximum => 127, :message => I18n.t(:must_be_less_than_128_characters_long)
  validates_uniqueness_of :name, :message => I18n.t(:has_already_been_taken)

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

  alias :focus :collection
  alias_attribute :summary_name, :name

  # Don't get dizzy.  This is all of the collections this community has collected.  This is the same thing as
  # "featured" collections or "endorsed" collections... that is the way it's done, now: you simply add the collection
  # to the community's focus.
  #
  # NOTE that this returns the collection_item, NOT the collection it points to!  This is so you can get the
  # annotation along with it.
  def collections
    self.collection.collection_items.collections
  end

  # TODO - test
  # Auto-joins the user to the community, and makes that person the owner.
  def initialize_as_created_by(user)
    mem = add_member(user)
    mem.update_attribute(:manager, true)
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
    raise EOL::Exceptions::CommunitiesMustHaveAManager if member.manager? && members.managers.count <= 1
    member.destroy
    self.reload
  end

  def has_member?(user)
    members.map {|m| m.user_id}.include?(user.id)
  end

  def logo_url(size = 'large')
    if logo_cache_url.blank?
      return "v2/logos/community_default.png"
    elsif size.to_s == 'small'
      DataObject.image_cache_path(logo_cache_url, '88_88')
    else
      DataObject.image_cache_path(logo_cache_url, '130_130')
      # ContentServer.logo_path(logo_cache_url, size)
    end
  end

  def top_active_members
    activity_log.map {|l|
      l['user_id']
    }.compact.sort.uniq.map {|uid|
      Member.find_by_community_id_and_user_id(id, uid)
    }.compact[0..3]
  end

private

  def attatch_focus
    Collection.create(:name => I18n.t(:default_focus_collection_name_from_community, :name => self.name), :special_collection_id => SpecialCollection.focus.id, :community_id => self.id)
  end

end
