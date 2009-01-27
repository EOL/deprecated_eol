class ContentPartnerAgreement < SpeciesSchemaModel
  
  belongs_to :agent
  before_create :set_all_other_agreements_to_not_current
  validates_presence_of :template, :if => :mou_url_blank?
  validates_presence_of :mou_url, :if => :template_blank? 
  validates_presence_of :agent_id
  
  def set_all_other_agreements_to_not_current
    
    self.template='' if self.template.blank?
    ContentPartnerAgreement.update_all("is_current=0",["agent_id=?",self.agent_id])
    
  end
  
  def mou_url_blank?
    self.mou_url.blank?
  end

  def template_blank?
    self.template.blank?
  end
  
  def self.create_new(params={})
    params[:agent_id] ||= '0'
    params[:template] ||= IO.read('app/views/content_partner/agreement_template.html.erb')
    params[:mou_url] ||= ''
    agreement=ContentPartnerAgreement.create(:agent_id=>params[:agent_id],:mou_url=>params[:mou_url],:last_viewed=>Time.now,:template=>params[:template],:is_current=>true,:number_of_views=>0) 
  end
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: content_partner_agreements
#
#  id              :integer(4)      not null, primary key
#  agent_id        :integer(4)      not null
#  ip_address      :string(255)
#  is_current      :boolean(1)      not null, default(TRUE)
#  last_viewed     :datetime
#  mou_url         :string(255)
#  number_of_views :integer(4)      not null, default(0)
#  signed_by       :string(255)
#  signed_on_date  :datetime
#  template        :text            not null
#  created_at      :datetime
#  updated_at      :datetime

