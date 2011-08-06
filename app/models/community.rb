class Community < ActiveRecord::Base

  include EOL::ActivityLoggable

  has_one :collection #TODO - didn't work? , :as => :focus

  has_many :members
  has_many :collection_items, :as => :object
  has_many :collection_endorsements
  has_many :collections, :through => :collection_endorsements # NOTE: be sure to check each for actually being endorsed!
  has_many :comments, :as => :parent

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
  validates_attachment_size :logo, :in => 0..5.megabyte,
    :if => self.column_names.include?('logo_file_name')

  index_with_solr :keywords => [ :name ], :fulltexts => [ :description ]

  alias :focus :collection
  alias_attribute :summary_name, :name

  # TODO - test
  # Auto-joins the user to the community, and makes that person the owner.
  def initialize_as_created_by(user)
    mem = user.join_community(self)
    mem.update_attribute(:manager, true)
    mem
  end

  # Returns the new member.  If you are NOT adding yourself, you should pass in :added_by.
  def add_member(user, opts = {})
    member = Member.create!(:user_id => user.id, :community_id => id)
    members << member
    added_by = opts[:added_by] ? opts[:added_by] : user
    member
  end

  def remove_member(user)
    member = Member.find_by_user_id_and_community_id(user.id, id)
    raise  I18n.t(:could_not_find_user)  unless member
    member.destroy
    self.reload
  end

  def has_member?(user)
    members.map {|m| m.user_id}.include?(user.id)
  end

  def logo_url(size = 'large')
    if logo_cache_url.blank?
      return "v2/icon_communities_tabs.png"
    elsif size.to_s == 'small'
      DataObject.image_cache_path(logo_cache_url, '88_88')
    else
      DataObject.image_cache_path(logo_cache_url, '130_130')
      # ContentServer.logo_path(logo_cache_url, size)
    end
  end

  def top_active_members
    # FIXME: This is just getting the top 3 members not the most active
    members[0..3]
  end

  def managers
    # FIXME: This is just getting the first couple of member not the managers
    members[0..2]
  end

  def pending_collections
    collection_endorsements.select {|c| c.pending? }.map {|c| c.collection }
  end

  def endorsed_collections
    collection_endorsements.select {|c| c.endorsed? }.map {|c| c.collection }
  end

private

  def attatch_focus
    Collection.create(:name => I18n.t(:default_focus_collection_name_from_community, :name => self.name), :special_collection_id => SpecialCollection.focus.id, :community_id => self.id)
  end

end
