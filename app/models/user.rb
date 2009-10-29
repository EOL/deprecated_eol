require "digest"

# NOTE - there is a method called #stale? (toward the bottom) which needs to be kept up-to-date with any changes made
# to the user model.  We *could* achieve a similar result with method_missing, but I worry that it would cause other
# problems.
class User < ActiveRecord::Base

  belongs_to :language
  has_and_belongs_to_many :roles

  before_save :check_curator_status
  
  #  TODO - this should be okay, but the account controller doesn't seem to like using this, because it forces this param in some cases:
#  attr_protected :curator_hierarchy_entry_id # Can't change this with update_attributes()

  belongs_to :curator_hierarchy_entry, :class_name => 'HierarchyEntry', :foreign_key => :curator_hierarchy_entry_id
  belongs_to :curator_verdict_by, :class_name => 'User', :foreign_key => :curator_verdict_by_id
  has_many   :curators_evaluated, :class_name => 'User', :foreign_key => :curator_verdict_by_id
  
  validates_presence_of :curator_verdict_by, :if => Proc.new { |obj| !obj.curator_verdict_at.nil? }
  validates_presence_of :curator_verdict_at, :if => Proc.new { |obj| !obj.curator_verdict_by.nil? }
  before_save {|obj| obj.credentials = '' if obj.credentials.nil?}   # TODO Move this into the check_curator_status before_save method

  validates_presence_of   :username, :if => :not_openid?

  validates_length_of     :username, :within => 4..32, :if => :not_openid?
  validates_length_of     :entered_password, :within => 4..16, :if => :not_openid?, :on => :create
  
  validates_presence_of   :given_name
  validates_format_of :email, :with =>%r{^(?:[_\+a-z0-9-]+)(\.[_\+a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4})$}i, :if => :not_openid?
  
  validates_uniqueness_of :username, :allow_nil => true
  # JRice removed this.  It was destroying staging, and would wreak havoc on over 700 users in production:
  # validates_uniqueness_of :email, :allow_nil => true
  
  validates_confirmation_of :entered_password

  has_many :data_object_tags, :class_name => DataObjectTags.to_s
  has_many :tags, :class_name => DataObjectTag.to_s, :through => :data_object_tags, :source => :data_object_tag
  has_many :comments
  has_many :last_curated_dates
  has_many :actions_histories
  
  attr_accessor :entered_password,:entered_password_confirmation,:curator_request
  attr_reader :full_name, :is_admin, :is_moderator
  
  def validate
    
     errors.add_to_base "Secondary hierarchy must be different than default" if !secondary_hierarchy_id.nil? && secondary_hierarchy_id == default_hierarchy_id
     
     if EOLConvert.to_boolean(curator_request) && credentials.blank?
       errors.add_to_base "You must indicate your credentials and area of expertise to request curator privileges."
    end
 
    if !credentials.blank? && (curator_scope.blank? && curator_hierarchy_entry_id.blank?)
       errors.add_to_base "You must either select a clade or indicate your scope to request curator privileges."
    end
    
  end
  
  def full_name
    return_value = given_name || ""
    return_value += " " + family_name unless family_name.blank?
    return_value
  end
  
  def objects_vetted
    # this needs to allow for eager loading
    CuratorDataObjectLog.find_all_by_user_id_and_curator_activity_id( self.id, CuratorActivity.approve! ).map(&:object)
  end 
  def total_objects_vetted
    # this needs to become a simple COUNT query
    CuratorDataObjectLog.find_all_by_user_id_and_curator_activity_id( self.id, CuratorActivity.approve! ).length
  end 

  def total_objects_curated
    CuratorDataObjectLog.count :conditions => ['user_id = ?', id] 
  end 
  def total_comments_curated
    CuratorCommentLog.count :conditions => ['user_id = ?', id] 
  end 

  def species_curated
    # we need to get the IDs of the curated data objects and then get the species for those (cross-database, so we can't effectively join)
    data_object_ids = CuratorDataObjectLog.find(:all, :select => 'distinct data_object_id', :conditions => [ 'user_id = ?', self.id ] ).map(&:data_object_id)
    species = TaxonConcept.from_data_objects(*data_object_ids)
  end
  def total_species_curated
    species_curated.length
  end

  def data_object_tags_for data_object
    data_object_tags.find_all_by_data_object_guid data_object.guid, :include => :data_object_tag
  end
  def tags_for data_object
    data_object_tags_for(data_object).map(&:tag).uniq
  end
  def tagged_objects
    data_object_tags.find_all.map(&:object)
  end
  def tag_keys
    tags.map(&:key).uniq
  end

  def can_curate? object
    return false unless curator_approved
    return false unless curator_hierarchy_entry_id
    return false unless object
    raise "Don't know how to curate object of type #{ object.class }" unless object.respond_to?:is_curatable_by?
    object.is_curatable_by? self
  end
  alias is_curator_for? can_curate?

  def can_curate_taxon_concept_id? taxon_concept_id
    can_curate? TaxonConcept.find(taxon_concept_id)
  end
  
  def approve_to_curate! clade
    clade = clade.id if clade.is_a?HierarchyEntry
    update_attribute :curator_hierarchy_entry_id, clade
    update_attribute :curator_approved, true
  end

  def set_curator approved,updated_by

    if (approved == true && self.curator_approved == false) # send the approval message if the user wasn't a curator and is now approved
      Notifier.deliver_curator_approved(self)
    elsif (approved == false && self.curator_approved == true) # only send the unapproval message if the user *was* a curator and is now rejected
      Notifier.deliver_curator_unapproved(self)       
    end
    
    self.curator_approved = approved
    self.curator_verdict_at = Time.now
    self.curator_verdict_by = updated_by
    self.save
    
    if approved
      self.roles << Role.curator unless has_curator_role?
    else
      self.roles.delete(Role.curator)
    end
    
  end
  
  def clear_curatorship updated_by,update_notes=''
    self.curator_approved=false
    self.credentials=''
    self.curator_scope=''
    self.curator_hierarchy_entry_id=''
    self.curator_verdict_at = Time.now
    self.curator_verdict_by = updated_by 
    self.roles.delete(Role.curator)
    self.notes='' if self.notes.nil?
    (self.notes+=' ; (' + updated_by.username + ' on ' + Date.today.to_s + '): ' + update_notes) unless update_notes.blank?
    self.save
  end
  
  # TODO - PRI MED - the vet/unvet methods inefficiently heck whether or not this user can_curate? the OBJECT.  that might involve lots of queries.
  #                  we likely need to be over to override this as we, in the app, already know whether or not a user can curate an item, 
  #                  so there's no reason to take this performance hit to 'double-check'

  # vet an object user can curate
  def vet object
    object.vet!(self) if object and object.respond_to? :vet! and can_curate? object
  end

  # unvet an object user can curate
  def unvet object
    object.unvet!(self) if object and object.respond_to? :unvet! and can_curate? object
  end

  # create a new user using default attributes and then update with supplied parameters
  def self.create_new options = {}
    new_user = User.new
    new_user.set_defaults
    new_user.attributes = options
    new_user
  end
  
  def self.authenticate(username,password)

    # try username first
    user = User.find_by_username_and_active(username,true)
    if !user.blank? && user.hashed_password==User.hash_password(password) 
      user.reset_login_attempts # found a matching username and password matched!
      return true,user
    elsif !user.blank?  # found a matching username, but password didn't match!
      user.invalid_login_attempt
      return false,"Invalid login or password"[]
    end
    
    # no match with username, next try email address, which is not necessarily unique in database
    users=User.find_all_by_email_and_active(username,true)
    return false,"Invalid login or password"[] if users.blank? # no email match either, returning nothing

    users.each do |u| # check all users with matching email addresses to see if one of them matches the password
      if u.hashed_password==User.hash_password(password) 
        u.reset_login_attempts # found a match with email and password
        return true,u
      else
        u.invalid_login_attempt # log the bad attempt for this user!
      end
    end
    
    if users.size > 1 
      return false,"The email address is not unique - you must enter a username"[] # more than 1 email address with no matching passwords
    else
      return false,"Invalid login or password"[]  # no matches yet again :(
    end
    
  end

  def reset_login_attempts
    self.update_attributes(:failed_login_attempts=>0) # reset the user's failed login attempts
  end
  
  def invalid_login_attempt
   self.update_attributes(:failed_login_attempts=>self.failed_login_attempts+1)
  end
  
  # I wanted to centralize this call, so we can quickly change from one kind of hashing to another.
  def self.hash_password(raw)
    Digest::MD5.hexdigest(raw)
  end

  # reset the password of the given username and email address, returns false if a problem occurred with a message to show, or true if successful with the new password and email address
  #
  # == Returns
  # [ Boolean, String ]:: Boolean fo whether the reset was successful & a message
  def self.reset_password(email,username)
  
    if username == '' # if user did not supply a username, just look by email address
      new_guy = User.find_all_by_email_and_active(email,true)
    elsif email == '' # if user did not supply an email, just look by username
      new_guy = User.find_all_by_username_and_active(username,true)
    else # otherwise look by both
      new_guy = User.find_all_by_username_and_email_and_active(username, email, true)
    end

    if new_guy.size==0 
        return false, "Sorry, but we could not locate your account."[:could_not_locate_account]
     elsif new_guy.size >1
        return false, "Sorry, but your email address is not unique - you must also specify a username."[:must_specify_username_too]      
    elsif new_guy[0].openid?
        return false, "Sorry, but your account uses OpenID and you must reset your password with your OpenID provider."[:openid_user_cannot_reset_password]      
    else
      chars    = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789' # Notice no 0/O or 1/l, since they are lame.
      new_password = ''
      8.times { new_password << chars[rand(chars.size)] }
      new_guy[0].password = new_password
      if new_guy[0].save
        return true, new_password, new_guy[0]
      else
        return false, "Sorry, a problem occurred updating your account - please try again later."[:problem_updating_account]      
      end  
    end

  end

  # returns true or false indicating if username is unique
  def self.unique_user?(username)
    return User.find_by_username(username).nil?
  end

  # returns true or false indicating if email is unique
  def self.unique_email?(email)
    return User.find_by_email(email).nil?
  end
  
  # set the defaults on this user object
  # TODO - move the defaults to the database (LOW PRIO)
  def set_defaults
    self.expertise = $DEFAULT_EXPERTISE.to_s
    self.language = Language.english
    self.mailing_list = false
    self.content_level = $DEFAULT_CONTENT_LEVEL
    self.vetted = $DEFAULT_VETTED
    self.default_taxonomic_browser=$DEFAULT_TAXONOMIC_BROWSER
    self.credentials = ''
    self.curator_scope = ''    
    self.active=true
    self.flash_enabled=true
  end

  def password
    entered_password
  end

  # set the password
  #
  # this sets both the #entered_password (for temporary retrieval)
  # and the #hashed_password
  #
  def password= value
    self.entered_password = value
    self.hashed_password = User.hash_password(value)
  end
  
  # set the language from the abbreviation
  def language_abbr=(value)
    self.language=Language.find_by_iso_639_1(value.downcase)  
  end
  
  # grab the language abbreviation
  def language_abbr
    return language.nil? ? Language.english.iso_639_1 : language.iso_639_1
  end

  def not_openid?      
    identity_url.blank? || identity_url.nil?
  end

  def openid?      
    !not_openid?
  end
      
  def is_moderator?
    @is_moderator ||= self.roles.include?(Role.moderator)
  end

  def has_curator_role?
    self.roles.include?(Role.curator)
  end

  def is_admin?
    @is_admin ||= self.roles.include?(Role.administrator)
  end
  
  def is_content_partner?
    @is_content_partner ||= self.roles.include?(Role.administrator)
  end

  def curator_attempted?
    !self.curator_hierarchy_entry.nil?
  end
  
  def is_curator?
    return (has_curator_role? && !self.curator_hierarchy_entry.blank?)
  end
  
  def last_curator_activity
    lcd = LastCuratedDate.find_by_user_id(self.id, :order => 'last_curated DESC', :limit => 1)
    return nil if lcd.nil?
    return lcd.last_curated
  end

  def show_unvetted?
    return !vetted
  end
  
  def check_curator_status
    if curator_hierarchy_entry.blank?  # remove the curator approval and role if they have no hierarchy entry set
      self.curator_approved=false
      self.roles.delete(Role.curator) unless self.roles.blank?
    else # be sure they have the curator role set if they have a curator hierarchy entry set
      self.roles.reload
      self.roles << Role.curator unless has_curator_role?
    end
  end

  alias :ar_to_xml :to_xml
  def to_xml(options = {})
    default_only   = [:id, :credentials, :username] # TODO - should we add Given / Family names? I'm not sure, privacy an issue
    options[:only] = (options[:only] ? options[:only] + default_only : default_only)
    ar_to_xml(options)
  end

  def tags_are_public_for_data_object?(data_object)
    return self.can_curate?(data_object)
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

  # Sets the visibility to invisible and the vetted to untrusted on all DataObjects submitted by this users.  NOT
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

  def content_page_cache_str
    return "#{language_abbr}_#{default_hierarchy_id.to_s}"
  end
  
  def taxa_page_cache_str
    return "#{language_abbr}_#{expertise}_#{vetted}_#{default_taxonomic_browser}_#{default_hierarchy_id}"
  end

  # This is a method that checks if the user model pulled from a session is actually up-to-date:
  #
  # YOU SHOULD ADD NEW USER ATTRIBUTES TO THIS METHOD WHEN YOU TWEAK THE USER TABLE.
  def stale?
    # if you add to this, use 'and'; KEEP ALL OLD METHOD CHECKS.
    return true unless self.attributes.keys.include?('filter_content_by_hierarchy')
  end

# -=-=-=-=-=-=- PROTECTED -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
protected   
  def password_required?
    not_openid? && (hashed_password.blank? || hashed_password.nil?)      
  end

end
