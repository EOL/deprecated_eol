class Community < ActiveRecord::Base

  include EOL::Feedable

  has_one :collection #TODO - didn't work? , :as => :focus
  alias :focus :collection

  has_many :collections # A bit confusing, this, but the singular is aliased.
  has_many :members
  has_many :roles
  has_many :collection_items, :as => :object

  after_create :attatch_focus

  # These are for will_paginate:
  cattr_reader :per_page
  @@per_page = 30

  validates_presence_of :name, :message => "cannot be empty."[]
  validates_length_of :name, :maximum => 127, :message => "must be less than 128 characters long."[]
  validates_uniqueness_of :name, :message => "has already been taken."[]

  def self.special
    cached_find(:name, $SPECIAL_COMMUNITY_NAME)
  end

  def self.create_special
    special = Community.special
    if special.nil? 
      special = Community.create(:name => $SPECIAL_COMMUNITY_NAME,
                                 :description => 'This is a special community for the curtors and admins of EOL.',
                                 :show_special_privileges => 1)
      special.add_default_roles
    end
    special_roles = {$ADMIN_ROLE_NAME => 20, $CURATOR_ROLE_NAME => 10, $ASSOCIATE_ROLE_NAME => 1}
    special_roles.keys.each do |key|
      role = Role.find(:first, :conditions => ['title = ? and community_id = ?', key, special.id])
      role ||= Role.create(:community_id => special.id, :title => key)
      role.privileges = Privilege.find(:all, :conditions => ["level <= ? and special = ?", special_roles[key], true])
    end
  end

  # TODO - test 
  # Adds the default roles, auto-joins the user to the community, and makes that person the owner.
  def initialize_as_created_by(user)
    new_roles = Role.add_defaults_to_community(self)
    user.join_community(self).add_role(new_roles.first)
  end

  def special?
    show_special_privileges > 0
  end

  def add_default_roles
    Role.add_defaults_to_community(self)
  end

  # Returns the new member.
  def add_member(user)
    member = Member.create!(:user_id => user.id, :community_id => id)
    members << member
    member
  end

  def remove_member(user)
    member = Member.find_by_user_id_and_community_id(user.id, id)
    raise "Couldn't find a member for this user"[:could_not_find_user] unless member
    member.destroy
    self.reload
  end

  def has_member?(user)
    members.map {|m| m.user_id}.include?(user.id)
  end

private 

  def attatch_focus
    # TODO - i18n
    Collection.create(:name => "#{self.name}'s Focus", :special_collection_id => SpecialCollection.focus.id, :community_id => self.id)
  end

end
