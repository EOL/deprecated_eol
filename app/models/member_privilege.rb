class MemberPrivilege < ActiveRecord::Base

  belongs_to :member
  belongs_to :privilege
  
  def revoked?
    revoked
  end

end
