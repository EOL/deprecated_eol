class Member < ActiveRecord::Base

  belongs_to :community
  belongs_to :user

  has_many :member_privileges
 
  has_and_belongs_to_many :roles

  validates_uniqueness_of :user_id, :scope => :community_id

  #TODO - named scopes for granted privileges and revoked privileges...

  def add_role(role)
    roles << role unless roles.include? role
  end

  def remove_role(role)
    roles = roles.reject {|r| r.id == role.id }
  end

  def assign_privileges(privs)
    privs.each do |priv|
      member_privileges << MemberPrivilege.create(:member_id => id, :privilege_id => priv.id)
    end
  end

  def revoke_privilege(priv)
    if existing_priv = MemberPrivilege.find(['member_id = ? AND privilege_id = ? AND revoked = ?', id, priv.id, false])
      existing_priv.revoked = true
      existing_priv.save!
    elsif ! had_privilege_revoked(priv)
      member_privileges << MemberPrivilege.create(:member_id => id, :privilege_id => priv.id, :revoked => true)
    end
  end

  # THIS IS SPECIFIC TO THE MEMBER (it excludes role privs).  If you want to check the member's roles too, use #can?
  # Chances are you want to use #can?...
  def has_privilege?(priv)
    MemberPrivilege.existis?(['member_id = ? AND privilege_id = ? AND revoked = ?', id, priv.id, false])
  end

  def had_privilege_revoked?(priv)
    MemberPrivilege.existis?(['member_id = ? AND privilege_id = ? AND revoked = ?', id, priv.id, true])
  end

  def can?(priv)
    return false if had_privilege_revoked?(priv)
    return true if has_privilege?(priv)
    return roles.detect {|r| r.can?(priv) }
  end

  def all_sorted_privileges
    privs = roles.map {|r| r.privileges}.flatten
    member_privileges.each do |mp|
      if mp.revoked?
        privs << mp.privilege unless mp.revoked?
      else
        privs.delete mp.privilege
      end
    end
    privs.uniq.sort_by {|p| p.name }
  end

end
