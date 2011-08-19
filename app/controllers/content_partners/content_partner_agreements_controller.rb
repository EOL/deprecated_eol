class ContentPartners::ContentPartnerAgreementsController < ContentPartnersController

  before_filter :check_authentication

  layout 'v2/partners'

  # POST /content_partners/:content_partner_id/agreements
  def create
    @partner = ContentPartner.find(params[:content_partner_id])
    if params[:commit_agree_to_terms]
      params[:content_partner_agreement][:signed_on_date] ||= Time.now
      params[:content_partner_agreement][:ip_address] = request.remote_ip
      params[:content_partner_agreement][:is_current] = true
    end
    @new_agreement = @partner.content_partner_agreements.build(params[:content_partner_agreement])
    access_denied unless current_user.can_create?(@new_agreement)
    if @new_agreement.save
      flash[:notice] = I18n.t(:content_partner_agreement_create_successful_notice)
    else
      flash[:notice] = I18n.t(:content_partner_agreement_create_unsuccessful_error)
    end
    redirect_to content_partner_resources_path(@partner)
  end

  # GET /content_partners/:content_partner_id/agreements/:id
  def show
    @partner = ContentPartner.find(params[:content_partner_id], :include => :content_partner_agreements)
    access_denied unless current_user.can_read?(@partner.agreement)
    @page_subheader = I18n.t(:content_partner_agreement_subheader)
  end

end