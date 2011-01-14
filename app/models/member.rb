class Member < ActiveRecord::Base

  belongs_to :community
  belongs_to :user

  has_many :member_privileges
 
  has_and_belongs_to_many :roles

  validates_uniqueness_of :user_id, :scope => :community_id

  #TODO - named scopes for granted privileges and revoked privileges...

  def add_role(role)
    self.roles << role unless self.roles.include? role
  end

  def remove_role(role)
    self.roles = self.roles.reject {|r| r.id == role.id }
  end

  def has_role?(role)
    self.roles.include? role
  end

  def grant_privileges(privs)
    privs.each do |priv|
      self.member_privileges << MemberPrivilege.create(:member_id => self.id, :privilege_id => priv.id)
    end
  end

  def grant_privilege(priv)
    grant_privileges([priv])
  end

  def revoke_privilege(priv)
    if existing_priv = MemberPrivilege.find_by_member_id_and_privilege_id_and_revoked(self.id, priv.id, false)
      existing_priv.revoked = true
      existing_priv.save!
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
    return self.roles.detect {|r| r.can?(priv) }
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
