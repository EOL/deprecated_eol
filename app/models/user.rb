# NOTE - there is a method called #stale? (toward the bottom) which needs to be kept up-to-date with any changes made
# to the user model.  We *could* achieve a similar result with method_missing, but I worry that it would cause other
# problems.
#
# Note that email is NOT a unique field: one email address is allowed to have multiple accounts.
# NOTE this inherist from MASTER.  All queries against a user need to be up-to-date, since this contains config information
# which can change quickly.  There is a similar clause in the execute() method in the connection proxy for masochism.
class User < $PARENT_CLASS_MUST_USE_MASTER

  belongs_to :curator_hierarchy_entry, :class_name => "HierarchyEntry", :foreign_key => :curator_hierarchy_entry_id
  belongs_to :curator_verdict_by, :class_name => "User", :foreign_key => :curator_verdict_by_id
  belongs_to :language
  belongs_to :agent

  has_many :curators_evaluated, :class_name => "User", :foreign_key => :curator_verdict_by_id
  has_many :members
  has_many :data_object_tags, :class_name => DataObjectTags.to_s
  has_many :tags, :class_name => DataObjectTag.to_s, :through => :data_object_tags, :source => :data_object_tag
  has_many :comments
  has_many :last_curated_dates
  has_many :actions_histories
  has_many :users_data_objects
  has_many :user_ignored_data_objects

  has_one    :user_info

  before_save :check_curator_status

  accepts_nested_attributes_for :user_info

  @email_format_re = %r{^(?:[_\+a-z0-9-]+)(\.[_\+a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4})$}i

  validate :ensure_unique_username_against_master, :on => :create

  validates_presence_of :curator_verdict_by, :if => Proc.new { |obj| !obj.curator_verdict_at.blank? }
  validates_presence_of :curator_verdict_at, :if => Proc.new { |obj| !obj.curator_verdict_by.blank? }
  validates_presence_of :username
  validates_presence_of :given_name

  validates_length_of :username, :within => 4..32
  validates_length_of :entered_password, :within => 4..16, :on => :create

  validates_format_of :email, :with => @email_format_re

  validates_confirmation_of :entered_password

  attr_accessor :entered_password, :entered_password_confirmation, :curator_request

  # create a new user using default attributes and then update with supplied parameters
  def self.create_new options = {}
    # NOTE - the agent_id is assigned in account controller, not in the model
    new_user = User.new
    new_user.send(:set_defaults) # It's a private method.  This is cheating, but we really DO want it private.
    new_user.attributes = options
    new_user
  end

  def self.authenticate(username, password)
    user = self.find_by_username_and_active(username, true)
    if user.blank?
      self.authenticate_by_email(username, password)
    elsif user.hashed_password == self.hash_password(password)
      user.reset_login_attempts # found a matching username and password matched!
      return true, user
    else
      user.invalid_login_attempt
      return false, "Invalid login or password"[]
    end
  end

  def self.authenticate_by_email(email, password)
    users = User.find_all_by_email_and_active(email, true)
    if users.blank?
      return self.fail_authentication_with_master_check(email)
    end
    users.each do |u| # check all users with matching email addresses to see if one of them matches the password
      if u.hashed_password == User.hash_password(password)
        u.reset_login_attempts # found a match with email and password
        return true, u
      else
        u.invalid_login_attempt # log the bad attempt for this user!
      end
    end
    if users.size > 1 # more than 1 email address with no matching passwords
      return false, "The email address is not unique - you must enter a username"[]
    else  # no matches yet again :(
      return false, "Invalid login or password"[]
    end
  end

  def self.fail_authentication_with_master_check(user_identifier)
    if self.active_on_master?(user_identifier)
      return false, "Your account is registered but not ready for you to access. Please try again in five minutes."[:account_registered_but_not_ready_try_later]
    else
      return false, "Invalid login or password"[]
    end
  end

  def self.generate_key
    Digest::SHA1.hexdigest(rand(10**16).to_s + Time.now.to_f.to_s)
  end

  def self.active_on_master?(username)
    User.with_master do
      user = User.find_by_username_and_active(username, true)
      user ||= User.find_by_email_and_active(username, true)
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
        JOIN #{ActivityLog.full_table_name} al ON u.id = al.user_id
      ORDER BY u.family_name, u.given_name"
    
    User.with_master do
      User.find_by_sql([sql])
    end
  end

  # TODO - test
  def self.curated_data_object_ids(arr_dataobject_ids, year, month, agent_id)
    obj_ids = []
    user_ids = []
    if(arr_dataobject_ids.length > 0 or agent_id == 'All') then
      sql = "SELECT ah.object_id data_object_id, ah.user_id
        FROM action_with_objects awo
          JOIN actions_histories ah ON ah.action_with_object_id = awo.id
          JOIN changeable_object_types cot ON ah.changeable_object_type_id = cot.id
          JOIN users u ON ah.user_id = u.id
        WHERE cot.ch_object_type = 'data_object' "
      if(agent_id != 'All') then
        sql += " AND ah.object_id IN (" + arr_dataobject_ids * "," + ")"
      end
      if(year.to_i > 0) then sql += " AND year(ah.updated_at) = #{year} AND month(ah.updated_at) = #{month} "
      end
      rset = User.find_by_sql([sql])
      rset.each do |post|
        obj_ids << post.data_object_id
        user_ids << post.user_id
      end
    end
    arr = [obj_ids, user_ids]
    return arr
  end

  # TODO - test
  def self.curated_data_objects(arr_dataobject_ids, year, month, page, report_type)
    page = 1 if page == 0
    sql = "SELECT ah.object_id data_object_id, cot.ch_object_type,
        awo.action_code code, u.given_name, u.family_name, ah.updated_at, ah.user_id
      FROM action_with_objects awo
        JOIN actions_histories ah ON ah.action_with_object_id = awo.id
        JOIN changeable_object_types cot ON ah.changeable_object_type_id = cot.id
        JOIN users u ON ah.user_id = u.id
      WHERE cot.ch_object_type = 'data_object'
        AND ah.object_id IN (" + arr_dataobject_ids * "," + ")"
    if(year.to_i > 0) then sql += " AND year(ah.updated_at) = #{year} AND month(ah.updated_at) = #{month} "
    end
    sql += " AND awo.action_code in ('trusted', 'untrusted', 'inappropriate', 'delete') "
    sql += " ORDER BY ah.id Desc"
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
  def self.unique_user?(username)
    User.with_master do
      User.count(:conditions => ['username = ?', username]) == 0
    end
  end

  # returns true or false indicating if email is unique
  def self.unique_email?(email)
    User.with_master do
      User.count(:conditions => ['email = ?', email]) == 0
    end
  end

  def password
    self.entered_password
  end

  def validate
    errors.add_to_base "Secondary hierarchy must be different than default" if !secondary_hierarchy_id.nil? && secondary_hierarchy_id == default_hierarchy_id
    if EOLConvert.to_boolean(curator_request)
      if(credentials.blank?)
        errors.add_to_base "You must indicate your credentials and area of expertise to request curator privileges."
      end
      if(curator_scope.blank? && curator_hierarchy_entry.blank?)
        errors.add_to_base "You must either select a clade or indicate your scope to request curator privileges."
      end
    end
  end

  def full_name
    return_value = given_name || ""
    return_value += " " + family_name unless family_name.blank?
    return_value
  end

  # TODO - test.  And move this (and many of the following methods) to their own module.
  def objects_vetted
    # TODO - use eager loading to avoid the #map
    CuratorDataObjectLog.find_all_by_user_id_and_curator_activity_id( id, CuratorActivity.approve ).map(&:object)
  end

  # TODO - test
  def total_objects_vetted
    # TODO - this needs to become a simple COUNT query
    CuratorDataObjectLog.find_all_by_user_id_and_curator_activity_id( id, CuratorActivity.approve ).length
  end

  # TODO - test
  # get the total objects curated for a particular curator activity type
  def total_objects_curated_by_action(action)
    curator_activity_id = CuratorActivity.send action+'!'
    if !curator_activity_id.nil?
      # TODO - change this to a #count.
      CuratorDataObjectLog.find_all_by_user_id_and_curator_activity_id( id, curator_activity_id ).length
    else
      return 0
    end
  end

  # TODO - test
  def data_objects_curated
    hashes = connection.execute("
      SELECT ah.object_id data_object_id, awo.action_code, ah.updated_at action_time
      FROM actions_histories ah
        JOIN action_with_objects awo ON (ah.action_with_object_id = awo.id)
      WHERE ah.user_id=#{id}
        AND ah.changeable_object_type_id=#{ChangeableObjectType.data_object.id}
        AND awo.action_code!='rate'
      GROUP BY data_object_id
      ORDER BY action_time DESC").all_hashes.uniq
  end

  # TODO - test
  def total_objects_curated
    data_objects_curated.length
  end

  # TODO - test
  def comments_curated
    connection.execute("
      SELECT awo.action_code, ah.updated_at action_time, c.*
      FROM actions_histories ah
        JOIN action_with_objects awo ON (ah.action_with_object_id = awo.id)
        JOIN comments c ON (ah.object_id = c.id)
      WHERE ah.user_id=#{id}
        AND ah.changeable_object_type_id=#{ChangeableObjectType.comment.id}
        AND ah.action_with_object_id!=#{ActionWithObject.created.id}").all_hashes.uniq
  end

  # TODO - test
  def total_comments_curated
    comments_curated.length
  end

  # TODO - test
  def taxon_concept_ids_curated
    connection.select_values("
      SELECT dotc.taxon_concept_id
      FROM actions_histories ah
        JOIN action_with_objects awo ON (ah.action_with_object_id = awo.id)
        JOIN #{DataObjectsTaxonConcept.full_table_name} dotc ON (ah.object_id = dotc.data_object_id)
      WHERE ah.user_id=#{id}
        AND ah.changeable_object_type_id=#{ChangeableObjectType.data_object.id}
        AND awo.action_code!='rate'
      GROUP BY ah.object_id
      ORDER BY ah.updated_at DESC").uniq
  end

  # TODO - test
  def total_species_curated
    taxon_concept_ids_curated.length
  end

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

  # object might be a data object or taxon concept
  def can_curate? object
    return false unless curator_approved
    return false unless curator_hierarchy_entry
    return false unless object
    raise "Don't know how to curate object of type #{ object.class }" unless object.respond_to?:is_curatable_by?
    object.is_curatable_by? self
  end
  alias is_curator_for? can_curate?

  # TODO - TEST (or remove... this seems silly.)
  def can_curate_taxon_concept_id? taxon_concept_id
    can_curate? TaxonConcept.find(taxon_concept_id)
  end

  def special
    @special ||= member_of(Community.special)
  end

  def approve_to_administrate
    grant_special_role(Role.administrator)
  end

  # Grants rights to their currently-selected HE.
  def approve_to_curate
    approve_to_curate_clade curator_hierarchy_entry
  end

  # Grants rights to a specific clade.
  def approve_to_curate_clade clade
    clade = clade.id if clade.is_a? HierarchyEntry
    self.curator_hierarchy_entry_id = clade
    self.curator_approved = true
    grant_special_role(Role.curator)
  end

  def grant_special_role(role)
    join_community(Community.special)
    special.add_role(role)
  end

  def revoke_curatorship
    self.curator_hierarchy_entry = nil
    self.curator_approved = false
    if special
      special.remove_role(Role.curator)
    end
  end

  # Grants or revokes rights to their currently-selected HE *and* updates fields indicating who allowed this (and when).
  def approve_to_curate_by_user approved, updated_by
    # TODO - this will happen EVERY time the user's record is updated by an admin. So the name curator_verdict_at is
    # now misleading because it will get updated even when nothing about the user is changed (the edit form is loaded and
    # immediately saved).
    self.curator_verdict_at = Time.now
    self.curator_verdict_by = updated_by
    if (approved && ! curator_approved) # The user wasn't a curator and is now approved
      approve_to_curate
      Notifier.deliver_curator_approved(self)
    elsif ((! approved) && curator_approved) # The user *was* a curator and is now rejected
      revoke_curatorship
      Notifier.deliver_curator_unapproved(self)
    end
    self.save! unless self.validating
  end

  def clear_curatorship updated_by, update_notes=""
    revoke_curatorship
    self.credentials = ""
    self.curator_scope = ""
    self.curator_verdict_at = Time.now
    self.curator_verdict_by = updated_by
    self.notes = "" if self.notes.nil?
    unless update_notes.blank?
      self.notes += ' ; (' + updated_by.username + ' on ' + Date.today.to_s + '): ' + update_notes
    end
    self.save!
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

  # set the language from the abbreviation
  def language_abbr=(value)
    self.language = Language.find_by_iso_639_1(value.downcase)
  end

  # grab the language abbreviation
  def language_abbr
    return language.nil? ? Language.english.iso_639_1 : language.iso_639_1
  end

  def is_moderator?
    return false if special.nil?
    special.can?(Privilege.show_hide_comments)
  end

  def has_special_role?(role)
    return false unless special
    special.roles.include?(role)
  end

  def is_admin?
    has_special_role?(Role.administrator)
  end

  # TODO - whaaa?  Seriously?  All CPs are admins?  ...We should change this.
  def is_content_partner?
    has_special_role?(Role.administrator)
  end

  def curator_attempted?
    !curator_hierarchy_entry.nil?
  end

  def is_curator?
    return (has_special_role?(Role.curator) && !curator_hierarchy_entry.blank?)
  end

  def selected_default_hierarchy
    hierarchy = Hierarchy.find_by_id(default_hierarchy_id)
    hierarchy.blank? ? '' : hierarchy.label
  end

  def last_curator_activity
    lcd = LastCuratedDate.find_by_user_id(id, :order => 'last_curated DESC', :limit => 1)
    return nil if lcd.nil?
    return lcd.last_curated
  end

  def show_unvetted?
    return !vetted
  end

  def check_curator_status
    credentials = '' if credentials.nil?
    if curator_hierarchy_entry.blank?
      revoke_curatorship
    else
      approve_to_curate
    end
  end

  alias :ar_to_xml :to_xml
  def to_xml(options = {})
    default_only   = [:id, :credentials, :username] # TODO - should we add Given / Family names? I'm not sure, privacy an issue
    options[:only] = (options[:only] ? options[:only] + default_only : default_only)
    ar_to_xml(options)
  end

  def tags_are_public_for_data_object?(data_object)
    return can_curate?(data_object)
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
    # if you add to this, use 'and'; KEEP ALL OLD METHOD CHECKS.
    return true unless attributes.keys.include?("filter_content_by_hierarchy")
  end

  def password_reset_url(original_port)
    port = ["80", "443"].include?(original_port.to_s) ? "" : ":#{original_port}"
    new_token = User.generate_key
    success = self.update_attributes(:password_reset_token => new_token, :password_reset_token_expires_at => 24.hours.from_now)
    http_string = $USE_SSL_FOR_LOGIN ? "https" : "http"
    if success
      return "#{http_string}://#{$SITE_DOMAIN_OR_IP}#{port}/account/reset_password/#{new_token}"
    else
      raise RuntimeError("Cannot save reset password data to the database") #TODO write it correctly
    end
  end

  def ensure_unique_username_against_master
    # NOTE - this weird id.blank? line was introduced because the :on => :create clause on the validation was not working.
    # Very frustrating.  So, essentially, we make sure this user is newly created before proceeding.
    if id.blank? # We don't care if the username is unique if the user is already in the system...
      errors.add('username', "#{username} is already taken") unless User.unique_user?(username)
    end
  end

  def rating_for_object_guid(guid)
    UsersDataObjectsRating.find_by_data_object_guid_and_user_id(guid, self.id)
  end

  def images_to_curate(options = {})
    page = options[:page].blank? ? 1 : options[:page].to_i
    per_page = options[:per_page].blank? ? 30 : options[:per_page].to_i
    hierarchy_entry_id = options[:hierarchy_entry_id] || curator_hierarchy_entry_id
    hierarchy_entry = HierarchyEntry.find(hierarchy_entry_id)
    vetted_id = options[:vetted_id].nil? ? Vetted.unknown.id : options[:vetted_id]

    solr_query = "ancestor_id:#{hierarchy_entry.taxon_concept_id} AND published:1 AND data_type_id:#{DataType.image.id} AND visibility_id:#{Visibility.visible.id}"

    unless options[:content_partner_id].blank?
      content_partner = ContentPartner.find(options[:content_partner_id].to_i)
      resource_clause = content_partner.agent.resources.collect{|r| r.id}.join(" OR resource_id:")
      if resource_clause.blank?
        solr_query << " AND resource_id:0"  # This will return nothing, when the content partner has no resources
      else
        solr_query << " AND (resource_id:#{resource_clause})"
      end
    end

    data_object_ids = EOL::Solr::SolrSearchDataObjects.images_for_concept(solr_query, :fields => 'data_object_id', :rows => 500, :sort => 'created_at desc')

    return [] if data_object_ids.empty?

    vetted_clause = vetted_id != 'all' ? " AND do.vetted_id = #{vetted_id}" : ""
    result = DataObject.find_by_sql("SELECT do.id
        FROM #{DataObject.full_table_name} do
          LEFT JOIN #{UserIgnoredDataObject.full_table_name} uido ON (do.id=uido.data_object_id)
        WHERE do.id IN (#{data_object_ids.join(',')})
          AND uido.id IS NULL
          #{vetted_clause}
        GROUP BY do.guid
        ORDER BY do.created_at DESC
        LIMIT 0, 300");

    start = per_page * (page - 1)
    last = start + per_page - 1
    data_object_ids_to_lookup = result[start..last].collect{|d| d.id}
    result[start..last] = DataObject.details_for_objects(data_object_ids_to_lookup, :skip_refs => true, :add_common_names => true, :add_comments => true, :sort => 'id desc')
    return result
  end

  def ignored_data_objects(options = {})
    hierarchy_entry_id = options[:hierarchy_entry_id] || curator_hierarchy_entry_id
    hierarchy_entry = HierarchyEntry.find(hierarchy_entry_id)
    data_type_clause = options[:data_type_id].nil? ? '' : " AND do.data_type_id = #{options[:data_type_id]}"
    
    data_object_ids = DataObjectsHierarchyEntry.find_by_sql("SELECT dohe.data_object_id 
        FROM #{DataObject.full_table_name} do
          JOIN #{UserIgnoredDataObject.full_table_name} uido ON (do.id=uido.data_object_id)
          JOIN #{DataObjectsHierarchyEntry.full_table_name} dohe ON (uido.data_object_id=dohe.data_object_id)
          JOIN #{HierarchyEntry.full_table_name} he on (dohe.hierarchy_entry_id = he.id)
          JOIN #{HierarchyEntry.full_table_name} he1 on (he.taxon_concept_id = he1.taxon_concept_id)
        WHERE uido.user_id = #{self.id} 
          AND he1.lft between #{hierarchy_entry.lft} and #{hierarchy_entry.rgt} 
          #{data_type_clause}
          AND he1.hierarchy_id = #{hierarchy_entry.hierarchy_id}
          GROUP BY do.guid
          ORDER BY do.created_at DESC");
    return [] if data_object_ids.empty?
    
    data_object_ids_to_lookup = data_object_ids.collect{|d| d.data_object_id}
    result = DataObject.details_for_objects(data_object_ids_to_lookup, :skip_refs => true, :add_common_names => true, :add_comments => true, :sort => 'id desc')
    return result
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
    ActivityLog.log(what, options.merge(:user => self)) if self.id && self.id != 0
  end

  # This is at the object level (and is specific to curators)
  def track_curator_activity(object, changeable_object_type, action, options = {})
    comment_id = options[:comment] ? options[:comment].id : nil
    untrust_reasons = options[:untrust_reasons] || nil
    taxon_concept_id = options[:taxon_concept_id] || nil
    action_with_object_id     = ActionWithObject.find_by_action_code(action).id
    changeable_object_type_id = ChangeableObjectType.find_by_ch_object_type(changeable_object_type).id
    actions_history = ActionsHistory.create(
      :user_id                   => self.id,
      :object_id                 => object.id,
      :changeable_object_type_id => changeable_object_type_id,
      :action_with_object_id     => action_with_object_id,
      :comment_id                => comment_id,
      :taxon_concept_id          => taxon_concept_id,
      :created_at                => Time.now,
      :updated_at                => Time.now
    )
    if untrust_reasons
      untrust_reasons.each do |ur|
        actions_history.untrust_reasons << ur
      end
    end
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
    member = Member.find_by_user_id_and_community_id(id, community.id)
    raise "Couldn't find a member for this user"[:could_not_find_user] unless member
    member.destroy
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
    return false if new_record? or changed?
    self.reload
  end

  def password_required?
    (hashed_password.blank? || hashed_password.nil?)
  end

end
