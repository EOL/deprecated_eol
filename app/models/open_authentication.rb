class OpenAuthentication < ActiveRecord::Base

  belongs_to :user

  validates_uniqueness_of :user_id, :scope => [:provider],
    :message => I18n.t(:provider_user_id_must_be_unique,
                       :scope => [:activerecord, :errors, :models, :open_authentications])


  validates_uniqueness_of :guid, :scope => [:provider],
    :message => I18n.t(:guid_provider_must_be_unique,
                       :scope => [:activerecord, :errors, :models, :open_authentications])

  def self.existing_authentication(open_authentication_provider, guid)
    OpenAuthentication.find_by_provider_and_guid(open_authentication_provider, guid, :include => :user)
  end

  def verified?
    ! verified_at.nil?
  end

  def verified
    # TODO: should we raise an exception here if we can't update verified_at?
    # It doesn't really affect user access just lets us know when connections are current.
    self.update_attribute(:verified_at, Time.now)
  end

  def not_verified
    # TODO: should we raise an exception here if we can't update verified_at?
    self.update_attribute(:verified_at, nil)
  end

end

