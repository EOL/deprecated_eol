class OpenAuthentication < ActiveRecord::Base

  belongs_to :user

  # Have to restrict validation on :user_id to update because user_id is nil for create with nested attributes.
  # So be careful when creating new users with nested attributes for open authentication because a missing
  # user_id on create will give ActiveRecord::StatementInvalid: Mysql::Error: Column 'user_id' cannot be null
  # This is fixed in Rails 3.0 with use if inverse_of, but this does not work for Rails 2.3.8
  # see http://stackoverflow.com/questions/935650/accepts-nested-attributes-for-child-association-validation-failing
  # TODO: Find a way to validate presence of user id on create with nested attributes.
  validates_presence_of :user_id, on: :update
  validates_presence_of :provider
  validates_presence_of :guid

  validates_uniqueness_of :user_id, scope: [:provider],
    message: I18n.t(:provider_user_id_must_be_unique,
                       scope: [:activerecord, :errors, :models, :open_authentications])


  validates_uniqueness_of :guid, scope: [:provider],
    message: I18n.t(:guid_provider_must_be_unique,
                       scope: [:activerecord, :errors, :models, :open_authentications])

  def can_be_deleted_by?(user_wanting_access)
    user_wanting_access.id == user_id
  end

  def verified?
    ! verified_at.nil?
  end

  def connection_established
    raise EOL::Exceptions::OpenAuthMissingConnectedUser,
      "User is nil for OpenAuthentication (id=#{id})."\
      " User should never be nil for OpenAuthentication." if user.nil?
    self.update_column(:verified_at, Time.now)
  end

  def connection_not_established
    self.update_column(:verified_at, nil)
  end

end

