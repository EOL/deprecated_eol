# Note that email is NOT a unique field: one email address is allowed to have
# multiple accounts. 
# NOTE this inherits from MASTER.  All queries against a user need to be 
# up-to-date, since this contains config information which can change quickly.
# There is a similar clause in the execute() method in the connection proxy for 
# masochism.

require 'eol/activity_loggable'

# NOTE - Curator loads a bunch of other relationships and validations.
# Also worth noting that #full_name (and the methods that count on it) need to
# know about curators, so you will see references to curator methods, there. 
# They didn't seem worth moving.
class User < ActiveRecord::Base
  establish_connection(Rails.env)

  include EOL::ActivityLoggable
  include IdentityCache

  belongs_to :language
  belongs_to :agent

  has_many :users_data_objects_ratings
  has_many :members
  has_many :comments
  has_many :users_data_objects
  has_many :collection_items, as: :collected_item
  has_many :containing_collections, through: :collection_items, source: :collection
  has_and_belongs_to_many :collections, conditions: 'collections.published = 1'
  has_and_belongs_to_many :collections_including_unpublished, class_name: Collection.to_s
  has_many :permissions_users
  has_many :permissions, through: :permissions_users
  has_many :communities, through: :members
  # TODO - These GA attributes should be moved to ContentPartner. (WEB-2995)
  has_many :google_analytics_partner_summaries
  has_many :google_analytics_partner_taxa
  has_many :resources, through: :content_partners
  has_many :users_user_identities
  has_many :user_identities, through: :users_user_identities
  has_many :worklist_ignored_data_objects
  has_many :pending_notifications
  has_many :open_authentications, dependent: :destroy
  has_many :forum_posts
  has_many :user_added_data, class_name: UserAddedData.to_s
  has_many :data_search_files

  # TODO - content_partners should be has_one:
  has_many :content_partners
  has_one :user_info
  has_one :notification

  scope :admins, conditions: ['admin IS NOT NULL']
  scope :curators, conditions: 'curator_level_id is not null'

  before_save :check_credentials
  before_save :encrypt_password
  before_save :remove_blank_username, unless: :eol_authentication?
  before_save :instantly_approve_curator_level, if: :curator_level_can_be_instantly_approved?
  after_save :update_watch_collection_name
  after_save :clear_cache

  after_create :add_agent

  before_destroy :destroy_comments
  # TODO: before_destroy :destroy_data_objects

  after_create :add_email_notification

  accepts_nested_attributes_for :user_info, :notification, :open_authentications

  @email_format_re = %r{^(?:[_\+a-z0-9-]+)(\.[_\+a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4})$}i

  validate :ensure_unique_username_against_master, if: :eol_authentication?

  validates_presence_of :given_name, if: :given_name_required?
  validates_presence_of :family_name, if: :first_last_names_required?
  validates_presence_of :username, if: :eol_authentication?

  validates_length_of :username, within: 4..32, if: :eol_authentication?
  validates_length_of :entered_password, within: 4..16, if: :password_validation_required?

  validates_confirmation_of :entered_password, if: :password_validation_required?

  validates_format_of :email, with: @email_format_re
  validates_confirmation_of :email, if: :email_confirmation_required?

  validates_acceptance_of :agreed_with_terms, accept: true

# CURATOR CLASS DECLARATIONS - TODO - extract:

  belongs_to :curator_verdict_by, class_name: "User", foreign_key: :curator_verdict_by_id
  belongs_to :curator_level
  belongs_to :requested_curator_level, class_name: CuratorLevel.to_s, foreign_key: :requested_curator_level_id

  has_many :curators_evaluated, class_name: "User", foreign_key: :curator_verdict_by_id
  has_many :curator_activity_logs
  has_many :curator_activity_logs_on_data_objects, class_name: CuratorActivityLog.to_s,
           conditions:
             Proc.new { "curator_activity_logs.changeable_object_type_id = #{ChangeableObjectType.raw_data_object_id}" }
  has_many :classification_curations

  after_create :join_curator_community_if_curator

  validates_presence_of :curator_verdict_at, if: Proc.new { |obj| !obj.curator_verdict_by.blank? }
  validates_presence_of :credentials, if: :curator_attributes_required?
  validates_presence_of :curator_scope, if: :curator_attributes_required?

  attr_accessor :curator_request

# END CURATOR CLASS DECLARATIONS
 
  index_with_solr keywords: [:username, :full_name]

  include EOL::Logos

  attr_accessor :entered_password, :entered_password_confirmation, :email_confirmation

  # Aaaaactually, this also preps the icon and tagline, since that's commonly shown with the title.
  def self.load_for_title_only(load_these)
    User.find(load_these,
      select: 'id, given_name, family_name, curator_level_id, username, logo_file_name, logo_cache_url, tag_line')
  end

  def self.sort_by_name(users)
    users.sort_by do |u|
      given = u.given_name.blank? ? u.family_name : u.given_name.strip
      family = u.family_name.blank? ? u.given_name : u.family_name.strip
      [family.downcase,
       given.downcase,
       u.username.downcase]
    end
  end

  def self.authenticate(username_or_email, password)
    user = self.find_by_username(username_or_email)
    users = user.blank? ? self.find_all_by_email(username_or_email) : [user]
    users.each do |u|
      if u.hashed_password == self.hash_password(password)
        u.reset_login_attempts
        return true, u
      end
    end
    # if we get here authentication was unsuccessful
    users.each do |u|
      u.invalid_login_attempt # log failed attempts
    end
    return false, users
  end

  def self.generate_key
    Digest::SHA1.hexdigest(rand(10**16).to_s + Time.now.to_f.to_s)
  end

  def self.active_on_master?(username_or_email)
    User.with_master do
      user = User.find_by_username_and_active(username_or_email, true)
      user ||= User.find_by_email_and_active(username_or_email, true)
      user.nil? ? false : true
    end
  end

  # TODO - test
  def self.users_with_submitted_text
    sql = "SELECT DISTINCT users.id , users.given_name, users.family_name
      FROM users Join users_data_objects ON users.id = users_data_objects.user_id
      ORDER BY users.family_name, users.given_name"
    rset = User.find_by_sql([sql])
    return rset
  end

  # TODO - This is only used in the admin controller, and can probably be removed.
  def self.users_with_activity_log
    sql = "SELECT distinct u.id , u.given_name, u.family_name
      FROM users u
        JOIN #{UserActivityLog.full_table_name} al ON u.id = al.user_id
      ORDER BY u.family_name, u.given_name"
    User.with_master do
      User.find_by_sql([sql])
    end
  end

  def self.hash_password(raw)
    Digest::MD5.hexdigest(raw)
  end
  
  def unsubscribe_key
    reload_all_values_if_missing([:created_at, :email])
    Digest::MD5.hexdigest(email + created_at.to_s + $UNSUBSCRIBE_NOTIFICATIONS_KEY)
  end

  # returns true or false indicating if username is unique
  def self.unique_user?(username, id = nil)
    User.with_master do
      if id.nil?
        User.count(conditions: ['username = ?', username]) == 0
      else
        User.count(conditions: ['username = ? AND id <> ?', username, id]) == 0
      end
    end
  end

  def self.cached(id)
    User.fetch(id)
  end

  # Note: this is only for Staging to help determine how to show cropped images
  def self.a_somewhat_recent_user
    @@a_somewhat_recent_user ||= User.find(:all, order: 'id desc', limit: 30).last
  end

  # Please use consistent format for naming Users across the site.  At the moment, this means using #full_name unless
  # you KNOW you have an exception.
  def full_name(options={})
    reload_all_values_if_missing([:curator_level_id, :given_name, :family_name, :username])
    if is_curator? # MUST show their name:
      return [given_name, family_name].join(' ').strip
    else # Other users show their full name when available, otherwise their username:
      if options[:ignore_empty_family_name] || username.blank?
        return [given_name, family_name].join(' ').strip unless given_name.blank? && family_name.blank?
      end
      return username if given_name.blank? || family_name.blank?
      return [given_name, family_name].join(' ').strip
    end
  end
  alias :summary_name :full_name # This is for collection item duck-typing, you need not use this elsewhere.
  alias :collected_name :full_name # This is for collection item duck-typing, you need not use this elsewhere.
  alias :name :full_name # This is for data tab only (ATM), used to mimic ContentPartner#name in real-estate.

  # Note that this can end up being expensive, but avoids errors.  Watch your qeries!
  def reload_all_values_if_missing(which)
    which = [which] unless which.is_a?(Array)
    reload_needed = false
    which.each do |attr|
      reload_needed = true unless self.has_attribute?(attr.to_sym) 
    end
    self.reload if reload_needed
  end

  # Don't use short_name unless you KNOW you should.
  def short_name
    reload_all_values_if_missing([:given_name, :family_name])
    return given_name unless given_name.blank?
    return family_name unless family_name.blank?
    username
  end

  # Some characters are not allowed in URLs.  For example, a dot (.) would screw up rails routes (since it would
  # think joe.user had a :username of 'joe' and a :format of 'user').  So we encode it:
  def self.username_from_verify_url(url)
    url.gsub(/__dot__/, '.').
      gsub(/__percent__/, '%').
      gsub(/__colon__/, ':').
      gsub(/__question__/, '?').
      gsub(/__slash__/, '/').
      gsub(/__amp__/, '&')
  end

  # TODO - test this. Wire this up to a controller. A user should be able to
  # "destroy" his account with this method (as of this writing, cannot).
  def deactivate
    update_column(:active, false)
    remove_from_index
  end

  def activate
    # Using update_column instead of updates_attributes to by pass validation
    # errors.
    update_column(:active, true)
    update_column(:validation_code, nil)
    add_to_index
    build_watch_collection
  end

  # Checks to see if one already exists (DO NOT use #watch_collection to do this, recursive!), and builds one if not:
  def build_watch_collection
    c = Collection.count_by_sql("SELECT COUNT(*) FROM collections c JOIN collections_users cu ON (c.id = cu.collection_id) WHERE cu.user_id = #{self.id} AND c.special_collection_id = #{SpecialCollection.watch.id}")
    if c == 0
      collections << collection = Collection.create(name: I18n.t(:default_watch_collection_name, username: self.full_name.titleize), special_collection_id: SpecialCollection.watch.id)
      return collection
    end
    return nil # Didn't build one.
  end

  def password
    self.entered_password
  end

  def taxa_commented
    return @taxa_commented unless @taxa_commented.nil?
    # list of taxa where user entered a comment
    set = Set.new
    # DataObject needs a lot to find its TC, so we preload all of those:
    Comment.preload_associations(comments.select { |c| c.parent_type == 'DataObject' },
      { parent: [ { data_objects_hierarchy_entries: [ :hierarchy_entry, :vetted ] }, :all_curated_data_objects_hierarchy_entries, { users_data_object: :vetted } ] },
      select: [ { data_objects: :id } ])
    comments.each do |comment|
      next unless comment.parent_id # Not worth checking...
      # NOTE - We're avoiding instantiating the parent unless it's a DataObject, so if we add new Comment parent
      # types, this code will need to be updated.
      case comment.parent_type
      when 'TaxonConcept'
        set << comment.parent_id
      when 'DataObject'
        set << comment.parent.taxon_concept_id if comment.parent && comment.parent.taxon_concept_id
      end
    end
    @taxa_commented = set.to_a
  end

  def total_comment_submitted
    return comments.count
  end

  def total_data_submitted
    return user_added_data.where(visibility_id: Visibility.visible.id, vetted_id: [Vetted.trusted.id, Vetted.unknown.id],
      deleted_at: nil).count
  end

  def total_wikipedia_nominated
    return WikipediaQueue.find_all_by_user_id(self.id).count
  end

  def can?(perm)
    permission = perm.is_a?(Permission) ? perm : Permission.send(perm)
    permissions.include?(permission)
  end

  def can_create?(resource)
    return false if resource.nil?
    resource.can_be_created_by?(self)
  end
  def can_read?(resource)
    return false if resource.nil?
    resource.can_be_read_by?(self)
  end
  def can_update?(resource)
    return false if resource.nil?
    resource.can_be_updated_by?(self)
  end
  def can_delete?(resource)
    return false if resource.nil?
    resource.can_be_deleted_by?(self)
  end

  def can_see_data?
    return false if ENV["NO_DATA"] # Trumps all other settings
    return true if (EolConfig.all_users_can_see_data rescue false)
    return true if can?(:see_data)
    false
  end

  def can_manage_community?(community)
    if member = member_of(community) # Not a community she's even in.
      return true if community && member.manager? # She's a manager
    end
    return false
  end

  def can_edit_collection?(collection)
    return false if collection.blank?
    return true if collection.users.include?(self) # Her collection
    collection.communities.each do |community|
      return true if can_manage_community?(community)
    end
    false # She's not a manager
  end

  def can_be_updated_by?(user_wanting_access)
    user_wanting_access.id == id || user_wanting_access.is_admin?
  end

  def grant_admin
    self.update_attributes(admin: true)
  end

  def grant_permission(perm)
    unless can?(perm)
      permission = perm.is_a?(Permission) ? perm : Permission.send(perm)
      permissions << permission
      permission.inc_user_count
    end
  end

  def revoke_permission(perm)
    if can?(perm)
      permission = perm.is_a?(Permission) ? perm : Permission.send(perm)
      permissions.delete permission
      permission.dec_user_count
    end
  end

  def clear_entered_password
    self.entered_password = ''
    self.entered_password_confirmation = ''
  end

  def reset_login_attempts
    self.failed_login_attempts = 0
  end

  def invalid_login_attempt
    self.failed_login_attempts += 1
    Rails.logger.error "Possible dictionary attack on user #{self.id} - #{self.failed_login_attempts} failed login attempts" if
      self.failed_login_attempts > 10 # Smells like a dictionary attack!
  end

  # set the password
  #
  # this sets both the #entered_password (for temporary retrieval)
  # and the #hashed_password
  #
  def password=(value)
    self.entered_password = value
    self.hashed_password = User.hash_password(value)
  end

  def watch_collection
    return @watch_collection if @watch_collection
    collection = Collection.find_by_sql("SELECT c.* FROM collections c JOIN collections_users cu ON (c.id = cu.collection_id) WHERE cu.user_id = #{self.id} AND c.special_collection_id = #{SpecialCollection.watch.id} LIMIT 1").first
    collection ||= build_watch_collection
    @watch_collection = collection
  end

  # set the language from the abbreviation
  def language_abbr=(value)
    self.language = Language.from_iso(value.downcase)
  end

  # grab the language abbreviation
  def language_abbr
    return language.nil? ? Language.english.iso_639_1 : language.iso_639_1
  end

  def default_language?
    language_id == Language.default.id
  end

  def is_admin?
    self.admin.nil? ? false : self.admin # return false for anonymous users
  end

  def is_active?
    self.active
  end

  def is_content_partner?
    content_partners.blank? ? false : true
  end

  # Returns an array of data objects submitted by this user.  NOT USED ANYWHERE.  This is a convenience method for
  # developers to use.
  def all_submitted_datos
    UsersDataObject.find(:all, conditions: "user_id = #{self[:id]}").map {|udo| DataObject.find(udo.data_object_id) }
  end

  def self.count_submitted_datos(user_id = nil)
    self.count_complex_query(UsersDataObject, 
                             %Q{SELECT user_id, COUNT(DISTINCT data_objects.guid) AS count
                                FROM users_data_objects
                                JOIN data_objects ON (users_data_objects.data_object_id = data_objects.id)
                                #{user_id ? "WHERE user_id = #{user_id}" : ""}
                                GROUP BY user_id}, user_id)
  end

  def self.count_objects_rated(user_id = nil)
    self.count_complex_query(UsersDataObject,
                             %Q{SELECT user_id, COUNT(DISTINCT data_object_guid) AS count
                                FROM users_data_objects_ratings
                                #{user_id ? "WHERE user_id = #{user_id}" : ""}
                                GROUP BY user_id}, user_id)
  end

  def self.count_comments_added(user_id = nil)
    self.count_complex_query(Comment,
                             %Q{SELECT user_id, COUNT(*) AS count
                                FROM comments
                                #{user_id ? "WHERE user_id = #{user_id}" : ""}
                                GROUP BY user_id}, user_id)
  end

  def self.count_user_rows(klass, user_id = nil)
    query = "SELECT user_id, COUNT(*) as count FROM #{klass.full_table_name} "
    if user_id.class == Fixnum
      query += "WHERE user_id = #{user_id} "
    elsif user_id.class == Array
      query += "WHERE user_id IN (#{user_id.join(',')}) "
    end
    query += "GROUP BY user_id"
    self.count_complex_query(klass, query, user_id)
  end


  def self.count_complex_query(klass, query, user_id = nil)
    results = klass.send(:connection).execute(query) rescue {}
    return_hash = {}
    results.each do |r|
      return_hash[r[0].to_i] = r[1].to_i
    end
    if user_id.class == Fixnum
      return return_hash[user_id] || 0
    end
    return_hash
  end

  # Returns an array of descriptions from all of the data objects submitted by this user.  NOT USED ANYWHERE.  This
  # is a convenience method for developers to use.
  def all_submitted_dato_descriptions
    all_submitted_datos.map {|dato| dato.description }
  end

  # Sets the visibility to invisible and the vetted to untrusted on all DataObjects submitted by this user.  NOT
  # USED ANYWHERE.  This is a convenience method for developers to use.  ...particularly where they are submitting
  # lots of text objects for testing, but don't want the rest of the world to see them when they are done.
  #
  # No return value; will raise exceptions if things fail.
  def hide_all_submitted_datos
    all_submitted_datos.each do |dato|
      dato.users_data_object.vetted = Vetted.untrusted
      dato.users_data_object.visibility = Visibility.invisible
      dato.users_data_object.save!
    end
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.update_column(:remember_token_expires_at, time)
    self.update_column(:remember_token, User.hash_password("#{email}--#{remember_token_expires_at}"))
  end

  def forget_me
    self.update_column(:remember_token_expires_at, nil)
    self.update_column(:remember_token, nil)
  end

  def content_page_cache_str
    "#{language_abbr}"
  end

  def taxa_page_cache_str
    "#{language_abbr}"
  end

  def ensure_unique_username_against_master
    errors.add('username', I18n.t(:username_taken, name: username)) unless User.unique_user?(username, id)
  end

  def rating_for_guid(guid)
    UsersDataObjectsRating.find_by_data_object_guid_and_user_id(guid, self.id, order: 'id desc').rating || 0
  end

  def ratings_for_guids(guids)
    return_ratings = {}
    ratings = UsersDataObjectsRating.find_all_by_data_object_guid_and_user_id(guids, self.id, order: 'id desc')
    ratings.each do |udor|
      next if return_ratings[udor.data_object_guid]
      return_ratings[udor.data_object_guid] = udor.rating
    end
    return_ratings
  end

  # This is *very* generalized and tracks nearly everything:
  def log_activity(what, options = {})
    UserActivityLog.log(what, options.merge(user: self)) if self.id && self.id != 0
  end

  def join_community(community)
    return unless community
    member = Member.find_by_community_id_and_user_id(community.id, id)
    unless member
      member = Member.create!(user_id: id, community_id: community.id)
      self.members << member
    end
    member
  end

  def leave_community(community)
    community.remove_member(self)
    self.reload
  end

  def is_member_of?(community)
    reload_if_stale
    self.members.map {|m| m.community_id}.include?(community.id)
  end

  def member_of(community)
    reload_if_stale
    self.members.select {|m| m.community_id == community.id}.first
  end

  # NOTE - This REMOVES the watchlist (using #shift)!
  def published_collections(as_user = nil)
    @published_collections ||= all_collections(as_user).shift && all_collections(as_user).select { |c| c.published? }
  end

  def unpublished_collections(as_user = nil)
    @unpublished_collections ||= all_collections(as_user).select { |c| ! c.published? }
  end

  # #collections is only a list of the collections the user *owns*.  This is a list that includes the collections the
  # user has access to through communities
  #
  # NOTE - this will ALWAYS put the watch collection first.
  def all_collections(as_user = nil)
    @all_collections ||= {}
    return @all_collections[as_user] if @all_collections.has_key?(as_user)
    editable_collections = collections_including_unpublished.reject { |c| c.watch_collection? }
    editable_collections += Collection.joins(communities: :members).where(['user_id = ? AND manager = 1', id])
    editable_collections = [watch_collection] + editable_collections.sort_by { |c| c.name.downcase }.uniq
    if as_user.is_a?(User)
      editable_collections.delete_if { |c| ! as_user.can_read?(c) }
    else
      editable_collections.delete_if { |c| ! c.published? }
    end
    @all_collections[as_user] = editable_collections.compact
  end

  # NOTE - this method ASSUMES it's only being called for a user's own collections.
  def all_non_resource_collections
    return @all_non_resource_collections if defined?(@all_non_resource_collections)
    collections = published_collections(self) || []
    Collection.preload_associations(collections, [ :resource, :resource_preview ])
    collections.delete_if { |c| c.is_resource_collection? }
    @all_non_resource_collections = collections
  end

  def ignored_data_object?(data_object)
    return false unless data_object
    return WorklistIgnoredDataObject.find_by_user_id_and_data_object_id(self.id, data_object.id)
  end

  def is_hidden?
    hidden == 1
  end

  def hide_comments(current_user)
    # remove comments from database
    comments = Comment.find_all_by_user_id(self.id)
    comments.each do |comment|
      comment.hide(current_user)
    end
  end

  def unhide_comments(current_user)
    comments = Comment.find_all_by_user_id(self.id)
    comments.each do |comment|
      comment.show(current_user)
    end
  end

  def hide_data_objects
    data_objects = UsersDataObject.find_all_by_user_id(self.id, include: :data_object).collect{|udo| udo.data_object}.uniq
    data_objects.each do |data_object|
      data_object.update_column(:published, 0)
      data_object.update_solr_index
    end
  end

  def unhide_data_objects
    data_objects = UsersDataObject.find_all_by_user_id(self.id, include: :data_object).collect{|udo| udo.data_object}.uniq
    data_objects.each do |data_object|
      data_object.update_column(:published, 1)
      data_object.update_solr_index
    end
  end

  def recover_account_token_matches?(token)
    (recover_account_token =~ /^[a-f0-9]{40}/) && (recover_account_token == token)
  end

  def recover_account_token_expired?
    recover_account_token_expires_at.blank? || Time.now > recover_account_token_expires_at
  end

  # An eol authentication indicates a user that has no open authentications, i.e. only has eol credentials
  def eol_authentication?
    open_authentications.blank?
  end

  # This returns false unless the user wants an email notification for the given type, then it returns the
  # NotificationFrequency object.
  def listening_to?(type)
    if notification
      fqz = notification.send(type)
      return false if fqz == NotificationFrequency.never
      return fqz
    else
      add_email_notification
      return false
    end
  end

  def unsent_notifications
    if notification
      if notification.last_notification_sent_at
        pending_notifications.unsent.after(notification.last_notification_sent_at)
      else
        pending_notifications.unsent
      end
    else
      add_email_notification
      return []
    end
  end

  # WARNING: Before you go and try to make notification_count and message_count use the same query and then filter
  # the results to count each type, rcognize (!) that they each use their own :after clause.  So be careful.
  def notification_count
    activity_log(news: true, filter: 'all',
      after: self.last_notification_at,
      skip_loading_instances: true,
      user: self).count
  end

  def message_count
    activity_log(news: true, filter: 'messages',
      after: self.last_message_at,
      skip_loading_instances: true,
      user: self).count
  end

  def add_as_recipient_if_listening_to(notification_type, recipients)
    if frequency = self.listening_to?(notification_type)
      recipients << { user: self, notification_type: notification_type, frequency: frequency }
    end
  end

  def to_s
    "User ##{id}: #{full_name}"
  end

  def clear_cache
    Rails.cache.delete("users/#{self.id}") if $CACHE
  end

  def vetted_types
    vetted_types = ['trusted', 'unreviewed']
    vetted_types << 'untrusted' if is_curator?
    vetted_types
  end

  def visibility_types
    vetted_types = ['visible']
    vetted_types << 'invisible' if is_curator?
    vetted_types
  end

  # TODO - does this belong here?  Is it duplicated somewhere else?
  def rating_weight
    is_curator? ? curator_level.rating_weight : 1
  end

  # Callback after_create, also used in controllers to ensure users have agents:
  def add_agent
    return unless agent_id.blank?
    begin
      # TODO: User may not have a full_name on creation so passing it here is possibly redundant.
      self.update_column(:agent_id, Agent.create_agent_from_user(full_name).id)
    rescue ActiveRecord::StatementInvalid
      # Interestingly, we are getting users who already have agents attached to them.  I'm not sure why, but it's causing registration to fail (or seem to; the user is created), and this is bad.
    end
  end

private

  def reload_if_stale
    return false if new_record? or changed? or frozen?
    self.reload
  end

  # We need to validate the password if hashed password is empty
  # i.e. on user#create, or if someone is trying to change it i.e. user#update
  # Don't need password when user authenticates with open authentication e.g. Facebook
  def password_validation_required?
    eol_authentication? && (hashed_password.blank? || hashed_password.nil? || ! self.entered_password.blank?)
  end

  # Callback before_save and before_update we only encrypt password if someone has entered a valid password
  def encrypt_password
    if self.valid? && ! self.entered_password.blank?
      self.hashed_password = User.hash_password(self.entered_password)
    else
      return true # encryption not required but we don't want to halt the process
    end
  end

  def email_confirmation_required?
    self.new_record? # TODO: require email confirmation if user changes their email on edit
  end

  def given_name_required?
    first_last_names_required? || !eol_authentication?
  end

  def first_last_names_required?
    wants_to_be_a_curator? || (!self.curator_level_id.nil? && !self.curator_level_id.zero?)
  end

  # Callback before_save MySQL has unique constraint on username but allows nil because username
  # is only required when open authentications are blank. We need to make sure we are not
  # sending blank strings to MySQL when username is not required
  def remove_blank_username
    self.username = nil if self.username.blank?
  end

  # Callback after_save
  def update_watch_collection_name
    collection = self.watch_collection rescue nil
    unless collection.blank?
      collection.name = I18n.t(:default_watch_collection_name, username: self.full_name.titleize)
      collection.save!
    end
  end

  def destroy_comments
    # TODO - generalize
    # remove comments from solr first
    begin
      solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_ACTIVITY_LOGS_CORE)
    rescue Errno::ECONNREFUSED => e
      logger.warn "** WARNING: Solr connection failed."
      return nil
    end
    solr_connection.delete_by_query("user_id:#{self.id}")

    # remove comments from database
    comments = Comment.find_all_by_user_id(self.id)
    comments.each do |comment|
      comment.destroy
    end
  end

  def add_email_notification
    Notification.create(user_id: self.id)
  end

# CURATOR METHODS - TODO - extract
public

  def curator_request
    return true unless is_curator? || (curator_scope.blank? && credentials.blank?)
  end

  def total_species_curated
    Curator.taxon_concept_ids_curated(self.id).length
  end

  def vet object
    object.vet(self) if object and object.respond_to? :vet and can_curate? object
  end

  def unvet object
    object.unvet(self) if object and object.respond_to? :unvet and can_curate? object
  end

  def revoke_admin
    self.update_attributes(admin: false)
  end

  def revoke_curator
    # TODO: This is weird, if we are revoking the curator access why not call update_attributes once and
    # add if-else loop to check if it successfully updated the attributes.
    unless curator_level_id == nil
      self.update_attributes(curator_level_id: nil)
    end
    self.leave_community(CuratorCommunity.get) if self.is_member_of?(CuratorCommunity.get)
    self.update_attributes(curator_verdict_by: nil,
                           curator_verdict_at: nil,
                           requested_curator_level_id: nil,
                           credentials: '', # Cannot be nil in the DB.
                           curator_scope: '', # Ditto.
                           curator_approved: false)
  end
  alias revoke_curatorship revoke_curator

  # before_save TODO - could replace this with actual method that does all approvals however that is going to work
  # TODO - not DRY with #grant_curator
  def instantly_approve_curator_level
    if wants_to_be_a_curator?
      unless already_has_requested_curator_level?
        was_curator = self.is_curator?
        self.curator_level_id = self.requested_curator_level_id
        self.curator_verdict_at = Time.now
        join_curator_community_if_curator unless was_curator
      end
      self.requested_curator_level_id = nil
    end
  end

  # conditional for before_save
  def curator_level_can_be_instantly_approved?
    self.wants_to_be_assistant_curator? || already_has_requested_curator_level?
  end

  # NOTE - default level implies that user.grant_curator means that they're supposed to be a full curator.  Makes
  # sense to me.  :P
  def grant_curator(level = :full, options = {})
    level = CuratorLevel.send(level)
    unless curator_level_id == level.id
      was_curator = self.is_curator?
      self.curator_level_id = level.id
      if options[:by]
        self.curator_verdict_by = options[:by]
        self.curator_verdict_at = Time.now
        self.curator_approved   = 1
        self.credentials ||= "Approved by admin" # NOTE - ASSUMING this method is admin-only!
        self.curator_scope ||= "N/A"             # NOTE - same...
      end
      self.save
      Notifier.curator_approved(self).deliver unless $LOADING_BOOTSTRAP || Rails.env.development?
      join_curator_community_if_curator unless was_curator
    end
    self.update_attributes(requested_curator_level_id: nil) # Not using validations; don't care if user is valid
    self
  end

  # NOTE: Careful!  This one means "any kind of curator"... which may not be what you want.  For example, an
  # assistant curator can't see vetting controls, so don't use this; use #min_curator_level?(:full) or the like.
  def is_curator?
    self.curator_level_id
  end

  # NOTE: Careful!  The next three methods are for checking the EXACT curator level.  See also #min_curator_level?.
  def master_curator?
    self.curator_level_id && self.curator_level_id == CuratorLevel.master.id
  end

  def full_curator?
    self.curator_level_id && self.curator_level_id == CuratorLevel.full.id
  end

  def assistant_curator?
    self.curator_level_id && CuratorLevel.assistant && self.curator_level_id == CuratorLevel.assistant.id
  end

  def is_pending_curator?
    !requested_curator_level.nil? && !requested_curator_level.id.zero?
  end

  def min_curator_level?(level)
    case level
    when :assistant
      return is_curator?
    when :full
      return master_curator? || full_curator?
    when :master
      return master_curator?
    end
  end

  def last_curator_activity
    last = CuratorActivityLog.find_by_user_id(id, order: 'created_at DESC', limit: 1)
    return nil if last.nil?
    return last.created_at
  end

  def check_credentials
    credentials = '' if credentials.nil?
  end

  # validation condition for required curator attributes
  def curator_attributes_required?
    (wants_to_be_a_curator? && !wants_to_be_assistant_curator?) || (is_curator? && !assistant_curator?)
  end

  def wants_to_be_a_curator?
    (!self.requested_curator_level_id.nil? && !self.requested_curator_level_id.zero?)
  end

  def wants_to_be_assistant_curator?
    self.requested_curator_level_id && CuratorLevel.assistant_curator && self.requested_curator_level_id == CuratorLevel.assistant_curator.id
  end

  def already_has_requested_curator_level?
    self.requested_curator_level_id == self.curator_level_id
  end
  def join_curator_community_if_curator
    self.join_community(CuratorCommunity.get) if self.is_curator?
  end

# END CURATOR METHODS
end
