class ContentPartnerAgreement < SpeciesSchemaModel
  belongs_to :content_partner
  before_create :set_all_other_agreements_to_not_current
  validates_presence_of :template, :if => :mou_url_blank?
  validates_presence_of :mou_url, :if => :template_blank?
  validates_presence_of :content_partner_id

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

  def set_all_other_agreements_to_not_current
    self.template='' if self.template.blank?
    ContentPartnerAgreement.update_all("is_current=0", ["content_partner_id = ?", self.content_partner_id])
    self.is_current = true
  end

  def mou_url_blank?
    self.mou_url.blank?
  end

  def template_blank?
    self.template.blank?
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
end
