class ContentPartners::ContentPartnerAgreementsController < ContentPartnersController

  before_filter :check_authentication

  layout 'v2/partners'

  # POST /content_partners/:content_partner_id/agreements
  def create
    @partner = ContentPartner.find(params[:content_partner_id])
    @new_agreement = @partner.content_partner_agreements.build(params[:content_partner_agreement])
    access_denied unless current_user.can_create?(@new_agreement)
    if @new_agreement.save
      flash[:notice] = I18n.t(:content_partner_agreement_create_successful_notice)
    else
      flash[:notice] = I18n.t(:content_partner_agreement_create_unsuccessful_error)
    end
    redirect_to content_partner_resources_path(@partner)
  end

end