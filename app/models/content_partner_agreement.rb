class ContentPartnerAgreement < SpeciesSchemaModel
  belongs_to :content_partner
  before_create :set_all_other_agreements_to_not_current
  validates_presence_of :body, :if => :mou_url_blank?
  validates_presence_of :mou_url, :if => :body_blank?
  validates_presence_of :content_partner_id

  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_created_by?(user_wanting_access)
    content_partner.user_id == user_wanting_access.id || user_wanting_access.is_admin?
  end
  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_read_by?(user_wanting_access)
    content_partner.user_id == user_wanting_access.id || user_wanting_access.is_admin?
  end
  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_updated_by?(user_wanting_access)
    content_partner.user_id == user_wanting_access.id || user_wanting_access.is_admin?
  end
  # TODO: This assumes one to one relationship between user and content partner and will need to be modified when we move to many to many
  def can_be_deleted_by?(user_wanting_access)
    content_partner.user_id == user_wanting_access.id || user_wanting_access.is_admin?
  end


#  def self.create_new(params={})
#    params[:template] ||= IO.read('app/views/content_partner/agreement_template.html.erb')
#    #params[:template] ||= IO.read('app/views/content_partner/agreement_template.html.haml')
#    params[:mou_url] ||= ''
#    agreement=ContentPartnerAgreement.create(
#      :content_partner_id => params[:content_partner_id],
#      :mou_url => params[:mou_url],
#      :last_viewed => Time.now,
#      :template => params[:template],
#      :is_current => true,
#      :number_of_views => 0)
#  end

  # override nil body for records that do not have an mou_url
  def body
    if read_attribute(:body).blank? && self.mou_url.blank?
      return ActionView::Base.new(Rails::Configuration.new.view_path).render(
        :partial => "content_partners/content_partner_agreements/template",
        :locals => { :partner => self.content_partner, :agreement => self })
    end
    read_attribute(:body)
  end

  # override nil created_at
  def created_at
    return Time.zone.now if read_attribute(:created_at).blank?
    read_attribute(:created_at)
  end

private
  def set_all_other_agreements_to_not_current
    self.template = '' if self.template.blank?
    ContentPartnerAgreement.update_all("is_current=0", ["content_partner_id = ?", self.content_partner_id])
    self.is_current = true
  end

  def mou_url_blank?
    self.mou_url.blank?
  end

  def body_blank?
    self.body.blank?
  end
end
