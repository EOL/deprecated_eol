class MemberPrivilege < ActiveRecord::Base

  belongs_to :member
  belongs_to :privilege

end
