class ContentPartners::ContentPartnerAgreementsController < ContentPartnersController

  before_filter :check_authentication

  layout 'v2/partners'

  # GET /content_partners/:content_partner_id/agreements/new
  def new
    @partner = ContentPartner.find(params[:content_partner_id], include: :content_partner_agreements)
    access_denied unless current_user.can_update?(@partner)
    @current_agreement = @partner.agreement
    new_agreement_params = { created_at: 0.seconds.from_now }
    # Content of new agreement is copied from the current agreement, if it exists, otherwise the template is used
    new_agreement_params[:body] = @current_agreement.body unless @current_agreement.blank?
    @agreement = @partner.content_partner_agreements.build(new_agreement_params)
    @page_subheader = I18n.t(:content_partner_agreement_subheader)
  end

  # POST /content_partners/:content_partner_id/agreements
  def create
    @partner = ContentPartner.find(params[:content_partner_id])
    set_params_when_agreeing_to_terms if params[:commit_agree_to_terms]
    @new_agreement = @partner.content_partner_agreements.build(params[:content_partner_agreement])
    access_denied unless current_user.can_create?(@new_agreement)
    if @new_agreement.save
      if params[:commit_agree_to_terms]
        flash[:notice] = I18n.t(:content_partner_agreement_signed_successful_notice)
      else
        flash[:notice] = I18n.t(:content_partner_agreement_create_successful_notice)
      end
      redirect_to content_partner_resources_path(@partner), status: :moved_permanently
    else
      if params[:commit_agree_to_terms]
        flash.now[:error] = I18n.t(:content_partner_agreement_signed_unsuccessful_error)
      else
        flash.now[:error] = I18n.t(:content_partner_agreement_create_unsuccessful_error)
      end
    end
  end

  # GET /content_partners/:content_partner_id/agreements/:id/edit
  def edit
    @partner = ContentPartner.find(params[:content_partner_id], include: :content_partner_agreements)
    @agreement = @partner.content_partner_agreements.find(params[:id])
    access_denied unless current_user.can_update?(@agreement)
    @page_subheader = I18n.t(:content_partner_agreement_subheader)
  end

  # PUT /content_partners/:content_partner_id/agreements/:id
  def update
    @partner = ContentPartner.find(params[:content_partner_id])
    @agreement = @partner.content_partner_agreements.find(params[:id])
    access_denied unless current_user.can_update?(@agreement)
    set_params_when_agreeing_to_terms if params[:commit_agree_to_terms]
    if @agreement.update_attributes(params[:content_partner_agreement])
      if params[:commit_agree_to_terms]
        flash[:notice] = I18n.t(:content_partner_agreement_signed_successful_notice)
      else
        flash[:notice] = I18n.t(:content_partner_agreement_update_successful_notice)
      end
      redirect_to content_partner_resources_path(@partner), status: :moved_permanently
    else
      if params[:commit_agree_to_terms]
        flash.now[:error] = I18n.t(:content_partner_agreement_signed_unsuccessful_error)
      else
        flash.now[:error] = I18n.t(:content_partner_agreement_update_unsuccessful_error)
      end
    end
  end

  # GET /content_partners/:content_partner_id/agreements/:id
  def show
    @partner = ContentPartner.find(params[:content_partner_id], include: :content_partner_agreements)
    @agreement = @partner.content_partner_agreements.find(params[:id])
    access_denied unless current_user.can_read?(@agreement)
    @page_subheader = I18n.t(:content_partner_agreement_subheader)
  end

private

  def set_params_when_agreeing_to_terms
    params[:content_partner_agreement][:signed_on_date] ||= Time.now
    params[:content_partner_agreement][:ip_address] ||= request.remote_ip
    params[:content_partner_agreement][:is_current] ||= true
  end
end
