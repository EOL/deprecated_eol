class ContentPartnerAgreement < ActiveRecord::Base

  belongs_to :content_partner

  before_save :set_all_other_agreements_to_not_current, if: :is_current

  validates_presence_of :body, if: :mou_url_blank?
  validates_presence_of :mou_url, if: :body_blank?
  validates_presence_of :content_partner_id

  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_created_by?(user_wanting_access)
    content_partner.user_id == user_wanting_access.id || user_wanting_access.is_admin?
  end
  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_read_by?(user_wanting_access)
    # (is_accepted? && is_current && content_partner.is_public) || commenting this out to temporarily restrict access due to privacy issues regarding contact info in agreements
    (content_partner.user_id == user_wanting_access.id || user_wanting_access.is_admin?)
  end
  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_updated_by?(user_wanting_access)
    !is_accepted? && (content_partner.user_id == user_wanting_access.id || user_wanting_access.is_admin?)
  end
  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_deleted_by?(user_wanting_access)
    user_wanting_access.is_admin?
  end

  # override default accessor for body if nil and partner does not have an mou_url
  def body
    if read_attribute(:body).blank? && self.mou_url.blank?
      av = ActionView::Base.new()
      av.view_paths = ActionController::Base.view_paths
      av.extend ApplicationHelper
      return av.render(
        partial: "content_partners/content_partner_agreements/template",
        locals: { partner: self.content_partner, agreement: self })
    end
    read_attribute(:body)
  end

  def is_accepted?
    !signed_on_date.blank?
  end

private
  def set_all_other_agreements_to_not_current
    self.template = '' if self.template.blank?
    ContentPartnerAgreement.update_all("is_current=0", ["content_partner_id = ? AND id != ?", self.content_partner_id, id])
  end

  def mou_url_blank?
    self.mou_url.blank?
  end

  def body_blank?
    self.body.blank?
  end
end
