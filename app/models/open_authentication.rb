class OpenAuthentication < ActiveRecord::Base

  belongs_to :user

  def self.authenticate(authentication)
    if user = User.find_by_id_and_active(authentication.user_id, true)
      return true, user
    end
    # if we get here authentication was unsuccessful
    return false, nil
  end
  
  def self.existing_authentication(open_authentication_provider, guid)
    OpenAuthentication.find_by_provider_and_guid(open_authentication_provider, guid, :include => :user)
  end

end