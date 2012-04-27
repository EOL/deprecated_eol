class OpenAuthentication < ActiveRecord::Base

  belongs_to :user

  validates_presence_of :user_id, :on => :update
  validates_presence_of :provider
  validates_presence_of :guid

  validates_uniqueness_of :user_id, :scope => [:provider],
    :message => I18n.t(:provider_user_id_must_be_unique,
                       :scope => [:activerecord, :errors, :models, :open_authentications])


  validates_uniqueness_of :guid, :scope => [:provider],
    :message => I18n.t(:guid_provider_must_be_unique,
                       :scope => [:activerecord, :errors, :models, :open_authentications])

  def can_be_deleted_by?(user_wanting_access)
    user_wanting_access.id == user.id
  end

  def verified?
    ! verified_at.nil?
  end

  def connection_established
    raise EOL::Exceptions::OpenAuthMissingConnectedUser,
      "User is nil for OpenAuthentication (id=#{id})."\
      " User should never be nil for OpenAuthentication." if user.nil?
    self.update_attribute(:verified_at, Time.now)
  end

  def connection_not_established
    self.update_attribute(:verified_at, nil)
  end

end

