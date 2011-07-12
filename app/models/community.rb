class Community < ActiveRecord::Base

  include EOL::ActivityLoggable

  has_one :collection #TODO - didn't work? , :as => :focus

  has_many :members
  has_many :roles
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
  validates_attachment_size :logo, :in => 0..0.5.megabyte,
    :if => self.column_names.include?('logo_file_name')

  index_with_solr :keywords => [:name, :description]

  alias :focus :collection
  alias_attribute :summary_name, :name

  def self.special
    special = cached_find(:name, $SPECIAL_COMMUNITY_NAME) # TODO - this should also have special_privs in it.
    raise "Special Community is missing. Perhaps you forgot to load it?" if special.nil? # For tests.
    special
  end

  def self.create_special
    special = nil
    begin
      special = Community.special
    rescue
      special = Community.create(:name => $SPECIAL_COMMUNITY_NAME,
                                 :description => 'This is a special community for the curtors and admins of EOL.',
                                 :show_special_privileges => 1)
      special.add_default_roles
    end
    special_roles = {$ADMIN_ROLE_NAME => 20, $CURATOR_ROLE_NAME => 10, $ASSOCIATE_ROLE_NAME => 1}
    special_roles.keys.each do |key|
      role = Role.find(:first, :conditions => ['title = ? and community_id = ?', key, special.id])
      role ||= Role.create(:community_id => special.id, :title => key)
      # TODO - we really should change Language#english to Language#default and have it set in a config file.
      # TODO - this is stupid, but migrations break because Language (the model) doesn't point to the right DB when
      # this runs, so it is undefined after recreating the DB (in which case we hardly need it anyway):
      begin
        role.privileges = Privilege.find(:all, :conditions => ["level <= ? and special = ?", special_roles[key], true])
      rescue ActiveRecord::StatementInvalid => e
        # Do nothing; this should only happen when developers recreate the databases and thus it hardly matters now.
      end
    end
  end

  # TODO - test
  # Adds the default roles, auto-joins the user to the community, and makes that person the owner.
  def initialize_as_created_by(user)
    new_roles = Role.add_defaults_to_community(self)
    mem = user.join_community(self)
    mem.add_role(new_roles.first)
    mem
  end

  def special?
    show_special_privileges > 0
  end

  def add_default_roles
    Role.add_defaults_to_community(self)
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
    logo_cache_url.blank? ? "v2/icon_communities_tabs.png" : ContentServer.logo_path(logo_cache_url, size)
  end

  def top_active_members
    # FIXME: This is just getting the top 3 members not the most active
    members[0..3]
  end

  def founder
    # FIXME: This is just getting the first member not the founder (can we get founder from feed - who created this community?).  JRice:  We could actually store this in the DB as a user_id... of course, if that user leaves, they will still be given credit, and that might be bad.  Hmmmn.  Not sure.
    members[0]
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
    # TODO - i18n
    Collection.create(:name => "#{self.name}'s Focus", :special_collection_id => SpecialCollection.focus.id, :community_id => self.id)
  end

end
