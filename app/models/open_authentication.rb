class OpenAuthentication < ActiveRecord::Base

  belongs_to :user

  def self.authenticate(authentication)
    if user = User.find_by_id_and_active(authentication.user_id, true)
      return true, user
    end
    # if we get here authentication was unsuccessful
    return false, nil
  end

end