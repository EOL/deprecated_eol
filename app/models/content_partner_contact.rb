# These individuals are associated with the roles such as "administrative contact" or "technical contact"
# are not used for attribution or logging in - they are simply used for administrative purposes when
# contacting the project.
class ContentPartnerContact < ActiveRecord::Base
  belongs_to :content_partner
  belongs_to :contact_role

  validates_presence_of :given_name, :family_name, :email
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  validates_length_of :full_name, :maximum => 255
  validates_length_of :title, :maximum => 20, :allow_nil => true
  validates_length_of :given_name, :maximum => 255
  validates_length_of :family_name, :maximum => 255
  validates_length_of :homepage, :maximum => 255, :allow_nil => true
  validates_length_of :email, :maximum => 75
  validates_length_of :telephone, :maximum => 30

  before_save :blank_not_null_fields
  before_save :save_full_name

  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_created_by?(user)
    content_partner.user_id == user.id || user.is_admin?
  end
  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_read_by?(user)
    content_partner.user_id == user.id || user.is_admin?
  end
  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_updated_by?(user)
    content_partner.user_id == user.id || user.is_admin?
  end
  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_deleted_by?(user)
    content_partner.user_id == user.id || user.is_admin?
  end

  def full_name
    self.save_full_name
  end

  protected
    def save_full_name
      self.full_name = "#{self.given_name} #{self.family_name}".strip
    end

    def blank_not_null_fields
      self.title ||= ""
      self.full_name ||= ""
      self.address ||= ""
    end
end
