class Member < ActiveRecord::Base

  # These are for use in forms:
  attr_accessor :new_role_id
  attr_accessor :new_privilege_id
  attr_accessor :removed_privilege_id
  attr_accessor :removed_role_id

  belongs_to :community
  belongs_to :user

  has_many :member_privileges
 
  has_and_belongs_to_many :roles

  validates_uniqueness_of :user_id, :scope => :community_id

  #TODO - named scopes for granted privileges and revoked privileges...

  def add_role(role)
    self.roles << role unless has_role?(role)
    if user.respond_to? :username
      community.feed.post(I18n.t("user_became_role_note", :username => user.username, :role => role.title), :feed_item_type_id => FeedItemType.content_update.id, :user_id => user.id)
    end
    self.roles
  end

  def remove_role(role)
    self.roles.delete(role)
  end

  def has_role?(role)
    self.roles.include? role
  end

  def grant_privileges(privs)
    privs.each do |priv|
      if self.has_privilege? priv
        # Do nothing.  We already have it.
      elsif self.had_privilege_revoked? priv
        MemberPrivilege.delete_all(:member_id => self.id, :privilege_id => priv.id)
        self.reload
      else
        self.member_privileges << MemberPrivilege.create(:member_id => self.id, :privilege_id => priv.id)
      end
    end
  end

  def grant_privilege(priv)
    grant_privileges([priv])
  end

  def revoke_privilege(priv)
    if existing_priv = MemberPrivilege.find_by_member_id_and_privilege_id_and_revoked(self.id, priv.id, false)
      MemberPrivilege.delete(existing_priv.id)
      self.reload
    elsif ! had_privilege_revoked?(priv)
      self.member_privileges << MemberPrivilege.create(:member_id => self.id, :privilege_id => priv.id, :revoked => true)
    end
  end

  # THIS IS SPECIFIC TO THE MEMBER (it excludes role privs).  If you want to check the member's roles too, use #can?
  # Chances are you want to use #can?...
  def has_privilege?(priv)
    MemberPrivilege.exists?(['member_id = ? AND privilege_id = ? AND revoked = ?', self.id, priv.id, false])
  end

  def had_privilege_revoked?(priv)
    MemberPrivilege.exists?(['member_id = ? AND privilege_id = ? AND revoked = ?', self.id, priv.id, true])
  end

  def can?(priv)
    return false if had_privilege_revoked?(priv)
    return true if has_privilege?(priv)
    return true unless self.roles.detect {|r| r.can?(priv) }.blank?
    return false
  end

  def can_edit_members?
    return Privilege.member_editing_privileges.map {|p| self.can? p }.include? true
  end

  def all_sorted_privileges
    privs = self.roles.map {|r| r.privileges}.flatten
    self.member_privileges.each do |mp|
      if mp.revoked?
        privs.delete mp.privilege
      else
        privs << mp.privilege
      end
    end
    privs.uniq.sort_by {|p| p.name }
  end

end
