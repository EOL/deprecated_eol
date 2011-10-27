# NOTE - there is a method called #stale? (toward the bottom) which needs to be kept up-to-date with any changes made
# to the user model.  We *could* achieve a similar result with method_missing, but I worry that it would cause other
# problems.
#
# Note that email is NOT a unique field: one email address is allowed to have multiple accounts.
# NOTE this inherist from MASTER.  All queries against a user need to be up-to-date, since this contains config information
# which can change quickly.  There is a similar clause in the execute() method in the connection proxy for masochism.

class User < $PARENT_CLASS_MUST_USE_MASTER

  include EOL::ActivityLoggable

  belongs_to :curator_verdict_by, :class_name => "User", :foreign_key => :curator_verdict_by_id
  belongs_to :language
  belongs_to :agent
  belongs_to :curator_level
  belongs_to :requested_curator_level, :class_name => CuratorLevel.to_s, :foreign_key => :requested_curator_level_id


  has_many :curators_evaluated, :class_name => "User", :foreign_key => :curator_verdict_by_id
  has_many :users_data_objects_ratings
  has_many :members
  has_many :data_object_tags, :class_name => DataObjectTags.to_s
  has_many :tags, :class_name => DataObjectTag.to_s, :through => :data_object_tags, :source => :data_object_tag
  has_many :comments
  has_many :curator_activity_logs
  has_many :curator_activity_logs_on_data_objects, :class_name => CuratorActivityLog.to_s,
             :conditions => "curator_activity_logs.changeable_object_type_id = #{ChangeableObjectType.raw_data_object_id}"
  has_many :users_data_objects
  has_many :collection_items, :as => :object
  has_many :containing_collections, :through => :collection_items, :source => :collection
  has_many :collections, :conditions => 'collections.published = 1'
  has_many :collections_including_unpublished, :class_name => Collection.to_s
  has_many :communities, :through => :members
  has_many :google_analytics_partner_summaries
  has_many :google_analytics_partner_taxa
  has_many :resources, :through => :content_partners
  has_many :users_user_identities
  has_many :user_identities, :through => :users_user_identities
  has_many :worklist_ignored_data_objects

  has_many :content_partners
  has_one :user_info
  belongs_to :default_hierarchy, :class_name => Hierarchy.to_s, :foreign_key => :default_hierarchy_id
  has_one :existing_watch_collection, :class_name => 'Collection', :conditions => 'special_collection_id = #{SpecialCollection.watch.id}'

  before_save :check_credentials
  before_save :encrypt_password
  before_save :instantly_approve_curator_level, :if => :curator_level_can_be_instantly_approved?
  after_save :update_watch_collection_name
  after_save :clear_cached_user

  before_destroy :destroy_comments
  # TODO: before_destroy :destroy_data_objects
   


  accepts_nested_attributes_for :user_info

  @email_format_re = %r{^(?:[_\+a-z0-9-]+)(\.[_\+a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4})$}i

  validate :ensure_unique_username_against_master

  validates_presence_of :curator_verdict_by, :if => Proc.new { |obj| !obj.curator_verdict_at.blank? }
  validates_presence_of :curator_verdict_at, :if => Proc.new { |obj| !obj.curator_verdict_by.blank? }
  validates_presence_of :credentials, :if => :curator_attributes_required?
  validates_presence_of :curator_scope, :if => :curator_attributes_required?
  validates_presence_of :given_name, :if => :first_last_names_required?
  validates_presence_of :family_name, :if => :first_last_names_required?
  validates_presence_of :username

  validates_length_of :username, :within => 4..32
  validates_length_of :entered_password, :within => 4..16, :if => :password_validation_required?

  validates_confirmation_of :entered_password, :if => :password_validation_required?

  validates_format_of :email, :with => @email_format_re

  validates_acceptance_of :agreed_with_terms, :accept => true

  # TODO: remove the :if condition after migrations are run in production
  has_attached_file :logo,
    :path => $LOGO_UPLOAD_DIRECTORY,
    :url => $LOGO_UPLOAD_PATH,
    :default_url => "/images/blank.gif",
    :if => self.column_names.include?('logo_file_name')

  validates_attachment_content_type :logo,
    :content_type => ['image/pjpeg','image/jpeg','image/png','image/gif', 'image/x-png'],
    :message => "image is not a valid image type",
    :if => self.column_names.include?('logo_file_name')
  validates_attachment_size :logo, :in => 0..$LOGO_UPLOAD_MAX_SIZE,
    :if => self.column_names.include?('logo_file_name')

  index_with_solr :keywords => [:username, :full_name]

  attr_accessor :entered_password, :entered_password_confirmation, :curator_request

  def self.sort_by_name(users)
    users.sort_by do |u|
      given = u.given_name.blank? ? u.family_name : u.given_name.strip
      family = u.family_name.blank? ? u.given_name : u.family_name.strip
      [family.downcase,
       given.downcase,
       u.username.downcase]
    end
  end

  # create a new user using default attributes and then update with supplied parameters
  def self.create_new options = {}
    # NOTE - the agent_id is assigned in user controller, not in the model
    new_user = User.new
    new_user.send(:set_defaults) # It's a private method.  This is cheating, but we really DO want it private.
    # Make sure a nil language doesn't upset things:
    options.delete(:language_id) if options.has_key?(:language_id) && options[:language_id].nil?
    new_user.attributes = options
    new_user
  end

  def self.authenticate(username_or_email, password)
    user = self.find_by_username_and_active(username_or_email, true)
    users = user.blank? ? self.find_all_by_email_and_active(username_or_email, true) : [user]
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
      user.nil? ? false : true  # Just cleaning up the nil, is all.  False is less likely to annoy.
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

  # TODO - test
  def self.users_with_activity_log
    sql = "SELECT distinct u.id , u.given_name, u.family_name
      FROM users u
        JOIN #{UserActivityLog.full_table_name} al ON u.id = al.user_id
      ORDER BY u.family_name, u.given_name"

    User.with_master do
      User.find_by_sql([sql])
    end
  end

  # TODO - test
  def self.curated_data_object_ids(arr_dataobject_ids, year, month, agent_id)
    obj_ids = []
    user_ids = []

    sql = "SELECT cal.object_id data_object_id, cal.user_id
      FROM #{LoggingModel.database_name}.activities acts
        JOIN #{LoggingModel.database_name}.curator_activity_logs cal ON cal.activity_id = acts.id
        JOIN changeable_object_types cot ON cal.changeable_object_type_id = cot.id
        JOIN users u ON cal.user_id = u.id
      WHERE cot.ch_object_type = 'data_object' "
    if(arr_dataobject_ids.length > 0) then
      sql += " AND cal.object_id IN (" + arr_dataobject_ids * "," + ")"
    end
    if(year.to_i > 0) then sql += " AND year(cal.updated_at) = #{year} AND month(cal.updated_at) = #{month} "
    end
    rset = User.find_by_sql([sql])
    rset.each do |post|
      obj_ids << post.data_object_id
      user_ids << post.user_id
    end

    arr = [obj_ids, user_ids]
    return arr
  end

  # TODO - test
  def self.curated_data_objects(arr_dataobject_ids, year, month, page, report_type)
    page = 1 if page == 0
    sql = "SELECT cal.object_id data_object_id, cot.ch_object_type,
        acts.id activity_id, u.given_name, u.family_name, cal.updated_at, cal.user_id
      FROM #{LoggingModel.database_name}.activities acts
        JOIN #{LoggingModel.database_name}.curator_activity_logs cal ON cal.activity_id = acts.id
        JOIN changeable_object_types cot ON cal.changeable_object_type_id = cot.id
        JOIN users u ON cal.user_id = u.id
      WHERE cot.ch_object_type = 'data_object'
        AND cal.object_id IN (" + arr_dataobject_ids * "," + ")"
    if(year.to_i > 0) then sql += " AND year(cal.updated_at) = #{year} AND month(cal.updated_at) = #{month} "
    end
    sql += " AND acts.id in (#{Activity.trusted.id}, #{Activity.untrusted.id}, #{Activity.inappropriate.id}, #{Activity.delete.id}) "
    sql += " ORDER BY cal.id Desc"
    if(report_type == "rss feed")
      self.find_by_sql [sql]
    else
      self.paginate_by_sql [sql], :per_page => 30, :page => page
    end
  end

  def self.hash_password(raw)
    Digest::MD5.hexdigest(raw)
  end

  # returns true or false indicating if username is unique
  def self.unique_user?(username, id = nil)
    User.with_master do
      if id.nil?
        User.count(:conditions => ['username = ?', username]) == 0
      else
        User.count(:conditions => ['username = ? AND id <> ?', username, id]) == 0
      end
    end
  end

  # returns true or false indicating if email is unique
  def self.unique_email?(email)
    User.with_master do
      User.count(:conditions => ['email = ?', email]) == 0
    end
  end

  # Please use consistent format for naming Users across the site.  At the moment, this means using #full_name unless
  # you KNOW you have an exception.
  def full_name
    if is_curator? # MUST show their name:
      return [given_name, family_name].join(' ').strip
    else # Other users show their full name when available, otherwise their username:
      return username if given_name.blank? || family_name.blank?
      return [given_name, family_name].join(' ').strip
    end
  end
  alias summary_name full_name # This is for collection item duck-typing, you need not use this elsewhere.

  # Don't use short_name unless you KNOW you should.
  def short_name
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

  def can_be_updated_by?(user_wanting_access)
    user_wanting_access.id == id || user_wanting_access.is_admin?
  end

  def curator_request
    return true unless is_curator? || (curator_scope.blank? && credentials.blank?)
  end

  def activate
    self.update_attributes(:active => true, :validation_code => nil)
    build_watch_collection
  end

  # Checks to see if one already exists (DO NOT use #watch_collection to do this, recursive!), and builds one if not:
  def build_watch_collection
    c = Collection.count(:conditions => {:special_collection_id => SpecialCollection.watch.id, :user_id => self.id})
    if c == 0
      Collection.create(:name => I18n.t(:default_watch_collection_name, :username => self.full_name.titleize), :special_collection_id => SpecialCollection.watch.id, :user_id => self.id)
    end
  end

  def password
    self.entered_password
  end

  # TODO
  # NOTE - this is currently ONLY used in an exported (CSV) report for admins... so... LOW priority.
  # get the total objects curated for a particular curator activity type
  def total_objects_curated_by_action(action)
    curator_activity_id = Activity.send action # approve may not work... looking into it TODO
    if !curator_activity_id.nil?
      # TODO
      raise "Unimplemented"
    else
      return 0
    end
  end

  def total_data_objects_curated
    connection.select_values("
      SELECT cal.object_id
      FROM #{CuratorActivityLog.database_name}.curator_activity_logs cal
        JOIN #{LoggingModel.database_name}.activities acts ON (cal.activity_id = acts.id)
      WHERE cal.user_id=#{id}
        AND cal.changeable_object_type_id IN(#{ChangeableObjectType.data_object_scope.join(",")})
        AND acts.id IN (#{Activity.raw_curator_action_ids.join(",")})
      ").uniq.length
  end

  def taxon_concept_ids_curated
    connection.select_values("
      SELECT dotc.taxon_concept_id
      FROM #{CuratorActivityLog.database_name}.curator_activity_logs cal
        JOIN #{LoggingModel.database_name}.activities acts ON (cal.activity_id = acts.id)
        JOIN #{DataObjectsTaxonConcept.full_table_name} dotc ON (cal.object_id = dotc.data_object_id)
      WHERE cal.user_id=#{id}
        AND cal.changeable_object_type_id IN(#{ChangeableObjectType.data_object_scope.join(",")})
        AND acts.id!=#{Activity.rate.id}
      ORDER BY cal.updated_at DESC").uniq
  end

  def total_species_curated
    taxon_concept_ids_curated.length
  end

  # Not sure yet its status in V2, commented temporarily
  # # TODO - test
  # def comment_curation_actions
  #   connection.select_values("
  #     SELECT cal.object_id
  #     FROM #{CuratorActivityLog.database_name}.curator_activity_logs cal
  #       JOIN #{LoggingModel.database_name}.activities acts ON (cal.activity_id = acts.id)
  #     WHERE cal.user_id=#{id}
  #       AND cal.changeable_object_type_id = #{ChangeableObjectType.comment.id}
  #       AND acts.id != #{Activity.create.id}
  #     ").uniq
  # end
  #
  # # TODO - test
  # def total_comments_curated
  #   comment_curation_actions.length
  # end

  # TODO - test all of these taggy things.  And move this to a module, I think.
  def data_object_tags_for data_object
    data_object_tags.find_all_by_data_object_guid data_object.guid, :include => :data_object_tag
  end
  def tags_for(data_object)
    data_object_tags_for(data_object).map(&:tag).uniq
  end
  def tagged_objects
    data_object_tags.find_all.map(&:object)
  end
  def tag_keys
    tags.map(&:key).uniq
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

  def grant_admin
    self.update_attributes(:admin => true)
  end

  def grant_curator(level = :full, options = {})
    level = CuratorLevel.send(level)
    unless curator_level_id == level.id
      self.update_attributes(:curator_level_id => level.id)
      Notifier.deliver_curator_approved(self) if $PRODUCTION_MODE
      if options[:user]
        self.update_attributes(:curator_verdict_by => options[:user],
                               :curator_verdict_at => Time.now)
      end
    end
    self.update_attributes(:requested_curator_level_id => nil)
  end
  alias approve_to_curate grant_curator

  def revoke_curator
    unless curator_level_id == nil
      self.update_attributes(:curator_level_id => nil)
    end
    self.update_attributes(:curator_verdict_by => nil,
                           :curator_verdict_at => nil,
                           :requested_curator_level_id => nil)
  end
  alias revoke_curatorship revoke_curator

  def clear_entered_password
    self.entered_password = ''
    self.entered_password_confirmation = ''
  end

  def vet object
    object.vet(self) if object and object.respond_to? :vet and can_curate? object
  end

  def unvet object
    object.unvet(self) if object and object.respond_to? :unvet and can_curate? object
  end

  def reset_login_attempts
    self.failed_login_attempts = 0
  end

  def invalid_login_attempt
    self.failed_login_attempts += 1
    logger.error "Possible dictionary attack on user #{self.id} - #{self.failed_login_attempts} failed login attempts" if
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
    collection = Collection.find_by_user_id_and_special_collection_id(self.id, SpecialCollection.watch.id)
    collection ||= build_watch_collection
    collection
  end

  # set the language from the abbreviation
  def language_abbr=(value)
    self.language = Language.from_iso(value.downcase)
  end

  # grab the language abbreviation
  def language_abbr
    return language.nil? ? Language.english.iso_639_1 : language.iso_639_1
  end

  # NOTE: Careful!  This one means "any kind of curator"... which may not be what you want.  For example, an
  # assistant curator can't see vetting controls, so don't use this; use #min_curator_level?(:full) or the like.
  def is_curator?
    self.curator_level_id
  end

  # NOTE: Careful!  The next three methods are for checking the EXACT curator level.  See also #min_curator_level?.
  def master_curator?
    self.curator_level_id == CuratorLevel.master.id
  end

  def full_curator?
    self.curator_level_id == CuratorLevel.full.id
  end

  def assistant_curator?
    self.curator_level_id == CuratorLevel.assistant.id
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

  def is_admin?
    self.admin.nil? ? false : self.admin # return false for anonymous users
  end

  def is_content_partner?
    content_partners.blank? ? false : true
  end

  def is_pending_curator?
    !requested_curator_level.nil? && !requested_curator_level.id.zero?
  end

  def can_edit_collection?(collection)
    return true if collection.user == self # Her collection
    return false if collection.user        # Not her collection, not a community collection.
    return false unless member = member_of(collection.community) # Not a community she's even in.
    return true if collection.community && member.manager? # She's a manager
    false # She's not a manager
  end

  def can_view_collection?(collection)
    return true if collection.published? || collection.user == self || self.is_admin?
    false
  end

  def selected_default_hierarchy
    hierarchy = Hierarchy.find_by_id(default_hierarchy_id)
    hierarchy.blank? ? '' : hierarchy.label
  end

  def last_curator_activity
    last = CuratorActivityLog.find_by_user_id(id, :order => 'created_at DESC', :limit => 1)
    return nil if last.nil?
    return last.created_at
  end

  def show_unvetted?
    return !vetted
  end

  def check_credentials
    credentials = '' if credentials.nil?
  end

  # Returns an array of data objects submitted by this user.  NOT USED ANYWHERE.  This is a convenience method for
  # developers to use.
  def all_submitted_datos
    UsersDataObject.find(:all, :conditions => "user_id = #{self[:id]}").map {|udo| DataObject.find(udo.data_object_id) }
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
      dato.vetted = Vetted.untrusted
      dato.visibility = Visibility.invisible
      dato.save!
    end
  end

  def default_hierarchy_valid?
    return(self[:default_hierarchy_id] and Hierarchy.exists?(self[:default_hierarchy_id]))
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token = User.hash_password("#{email}--#{remember_token_expires_at}")
    self.save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    self.save(false)
  end

  def content_page_cache_str
    str = "#{language_abbr}"
    str += "_#{default_hierarchy_id.to_s}" unless default_hierarchy_id.to_s.blank?
    str
  end

  def taxa_page_cache_str
    return "#{language_abbr}_#{expertise}_#{vetted}_#{default_taxonomic_browser}_#{default_hierarchy_id}"
  end

  # This is a method that checks if the user model pulled from a session is actually up-to-date:
  #
  # YOU SHOULD ADD NEW USER ATTRIBUTES TO THIS METHOD WHEN YOU TWEAK THE USER TABLE.
  def stale?
    # KEEP ALL OLD METHOD CHECKS
    return true unless attributes.keys.include?("filter_content_by_hierarchy")
    return true unless attributes.keys.include?("admin") # V2
    return false
  end

  def ensure_unique_username_against_master
    errors.add('username', I18n.t(:username_taken, :name => username)) unless User.unique_user?(username, id)
  end

  def rating_for_object_guid(guid)
    UsersDataObjectsRating.find_by_data_object_guid_and_user_id(guid, self.id, :order => 'id desc')
  end

  def rating_for_object_guids(guids)
    return_ratings = {}
    ratings = UsersDataObjectsRating.find_all_by_data_object_guid_and_user_id(guids, self.id, :order => 'id desc')
    ratings.each do |udor|
      next if return_ratings[udor.data_object_guid]
      return_ratings[udor.data_object_guid] = udor
    end
    return_ratings
  end

  def uservoice_token
    return nil if $USERVOICE_ACCOUNT_KEY.blank?
    user_hash = Hash.new
    user_hash[:guid] = "eol_#{self.id}"
    user_hash[:expires] = Time.now + 5.hours
    user_hash[:email] = self.email
    user_hash[:display_name] = self.full_name
    user_hash[:locale] = self.language.iso_639_1
    self.is_admin? ? user_hash[:admin]='accept' : user_hash[:admin]='deny'
    json_token = user_hash.to_json

    key = EzCrypto::Key.with_password $USERVOICE_ACCOUNT_KEY, $USERVOICE_API_KEY
    encrypted = key.encrypt(json_token)
    token = CGI.escape(Base64.encode64(encrypted)).gsub(/\n/, '')
  end

  # This is *very* generalized and tracks nearly everything:
  def log_activity(what, options = {})
    UserActivityLog.log(what, options.merge(:user => self)) if self.id && self.id != 0
  end

  def join_community(community)
    member = Member.find_by_community_id_and_user_id(community.id, id)
    unless member
      member = Member.create!(:user_id => id, :community_id => community.id)
      self.members << member
    end
    member
  end

  def leave_community(community)
    community.remove_member(self)
    self.reload
  end

  def member_of?(community)
    reload_if_stale
    self.members.map {|m| m.community_id}.include?(community.id)
  end

  def member_of(community)
    reload_if_stale
    self.members.select {|m| m.community_id == community.id}.first
  end

  # override the logo_url column in the database to contruct the path on the content server
  def logo_url(size = 'large')
    if logo_cache_url.blank?
      return "v2/logos/user_default.png"
    elsif size.to_s == 'small'
      DataObject.image_cache_path(logo_cache_url, '88_88')
    else
      DataObject.image_cache_path(logo_cache_url, '130_130')
      # ContentServer.logo_path(logo_cache_url, size)
    end
  end

  # #collections is only a list of the collections the user *owns*.  This is a list that includes the collections the
  # user has access to through communities
  #
  # NOTE - this will ALWAYS put the watch collection first.
  def all_collections(logged_in_as_user = false)
    editable_collections = collections_including_unpublished.reject {|c| c.watch_collection? }
    if logged_in_as_user
      editable_collections.delete_if{ |c| !c.published? && !c.is_resource_collection? }
    else
      editable_collections.delete_if{ |c| !c.published? }
    end
    editable_collections += members.managers.map {|member| member.community.collection }
    editable_collections = [watch_collection] + editable_collections.sort_by(&:name)
    editable_collections.compact
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
      comment.hide(current_user)
    end
    
  end
  
  def hide_data_objects
    data_objects = UsersDataObject.find_all_by_user_id(self.id, :include => :data_object).collect{|udo| udo.data_object}.uniq
    data_objects.each do |data_object|
      puts data_object.id
      data_object.published = 0
      data_object.save
      data_object.update_solr_index
    end    
  end
  
  def unhide_data_objects
    data_objects = UsersDataObject.find_all_by_user_id(self.id, :include => :data_object).collect{|udo| udo.data_object}.uniq
    data_objects.each do |data_object|
      data_object.published = 1
      data_object.save
      data_object.update_solr_index
    end
  end

private

  # set the defaults on this user object
  # TODO - move the defaults to the database (LOW PRIO)
  def set_defaults
    self.default_taxonomic_browser = $DEFAULT_TAXONOMIC_BROWSER
    self.expertise     = $DEFAULT_EXPERTISE.to_s
    self.language      = Language.english
    self.mailing_list  = false
    self.content_level = $DEFAULT_CONTENT_LEVEL
    self.vetted        = $DEFAULT_VETTED
    self.credentials   = ''
    self.curator_scope = ''
    self.active        = true
    self.flash_enabled = true
  end
    
  def reload_if_stale
    return false if new_record? or changed? or frozen?
    self.reload
  end

  def password_required?
    hashed_password.blank? || hashed_password.nil? || ! self.entered_password.blank?
  end

  # We need to validate the password if hashed password is empty i.e. on user#create, or if someone is trying to change it i.e. user#update
  def password_validation_required?
    password_required? || ! self.entered_password.blank?
  end

  # Callback before_save and before_update we only encrypt password if someone has entered a valid password
  def encrypt_password
    if self.valid? && ! self.entered_password.blank?
      self.hashed_password = User.hash_password(self.entered_password)
    else
      return true # encryption not required but we don't want to halt the process
    end
  end
  
  # 

  # validation condition for required curator attributes
  def curator_attributes_required?
    return false unless self.class.column_names.include?('requested_curator_level_id')
    (!self.requested_curator_level_id.nil? && !self.requested_curator_level_id.zero? &&
      self.requested_curator_level_id != CuratorLevel.assistant_curator.id) ||
    (!self.curator_level_id.nil? && !self.curator_level_id.zero? &&
      self.curator_level_id != CuratorLevel.assistant_curator.id)
  end

  def first_last_names_required?
    return false unless self.class.column_names.include?('requested_curator_level_id')
    (!self.requested_curator_level_id.nil? && !self.requested_curator_level_id.zero?) ||
    (!self.curator_level_id.nil? && !self.curator_level_id.zero?)
  end

  # before_save TODO - could replace this with actual method that does all approvals however that is going to work
  # TODO - this is not hooked up with the V1 curator approved attributes - need more info
  def instantly_approve_curator_level
    unless self.requested_curator_level_id.nil? || self.requested_curator_level_id.zero?
      self.curator_level_id = self.requested_curator_level_id
      self.requested_curator_level_id = nil
    end
  end

  # conditional for before_save
  def curator_level_can_be_instantly_approved?
    return false unless self.class.column_names.include?('requested_curator_level_id')
    self.requested_curator_level_id == CuratorLevel.assistant_curator.id ||
    self.requested_curator_level_id == self.curator_level_id
  end

  # Callback after_save
  def update_watch_collection_name
    collection = self.existing_watch_collection rescue nil
    unless collection.blank?
      collection.name = I18n.t(:default_watch_collection_name, :username => self.full_name.titleize)
      collection.save!
    end
  end

  # Callback after_save
  def clear_cached_user
    $CACHE.delete("users/#{self.id}") if $CACHE
  end

  def destroy_comments
    # remove comments from solr first
    begin
      solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_ACTIVITY_LOGS_CORE)
    rescue Errno::ECONNREFUSED => e
      puts "** WARNING: Solr connection failed."
      return nil
    end
    solr_connection.delete_by_query("user_id:#{self.id}")

    # remove comments from database
    comments = Comment.find_all_by_user_id(self.id)
    comments.each do |comment|
      comment.destroy
    end
  end
  
  
end
