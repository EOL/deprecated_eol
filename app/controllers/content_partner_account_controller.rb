class ContentPartnerAccountController < ApplicationController
  before_filter :check_authentication
  layout 'user_profile'

  def dashboard
    @page_header = I18n.t("content_partner_dashboard_header")
    if params[:register] && !current_user.content_partner
      current_user.content_partner = ContentPartner.new(:content_partner_status => ContentPartnerStatus.active)
    end
    @user = User.find(current_user.id)
  end

  def profile
    @page_header = I18n.t("content_partner_profile_menu")

    if params[:user]
      current_user.content_partner.update_attributes(params[:user][:content_partner])
      params[:user].delete(:content_partner)
      alter_current_user do |user|
        user.update_attributes(params[:user])
        upload_logo(user) unless params[:user][:logo].blank?
      end
      current_user.content_partner.log_completed_step!('partner')
      redirect_to(:action => 'dashboard')
    end

    @user = User.find(current_user.id)
  end

  def contacts
    @page_header = I18n.t("contacts")
    @user = User.find(current_user.id)
  end

  def add_contact
    @page_header = I18n.t("add_contact")
    @content_partner_contact = current_user.content_partner.content_partner_contacts.build(params[:content_partner_contact])

    if request.post?
      if @content_partner_contact.save
        flash[:notice] = I18n.t("contact_created")
        redirect_to(:action => 'contacts')
      end
    end
  end



  # The next several methods are the Partner Agreement Steps
  def licensing
    @page_header = I18n.t("licensing")
    @user = User.find(current_user.id)
    @user.content_partner.log_seen_step!('licensing')

    if request.post? && @user.content_partner.update_attributes(params[:content_partner])
      @user.content_partner.log_completed_step!('licensing')
      redirect_to(:action => 'attribution') unless params[:save_type] && params[:save_type] == 'save'
    end
  end

  def attribution
    @page_header = I18n.t("attribution")
    @user = User.find(current_user.id)
    @user.content_partner.log_seen_step!('attribution')

    if request.post? && @user.content_partner.update_attributes(params[:content_partner])
      @user.content_partner.log_completed_step!('attribution')
      redirect_to(:action => 'roles') unless params[:save_type] && params[:save_type] == 'save'
    end
  end

  def roles
    @page_header = I18n.t("roles")
    @user = User.find(current_user.id)
    @user.content_partner.log_seen_step!('roles')

    if request.post? && @user.content_partner.update_attributes(params[:content_partner])
      @user.content_partner.log_completed_step!('roles')
      redirect_to(:action => 'transfer_overview') unless params[:save_type] && params[:save_type] == 'save'
    end
  end

  def transfer_overview
    @page_header = I18n.t("transfer_schema_overview")
    @user = User.find(current_user.id)
    @user.content_partner.log_seen_step!('transfer_overview')

    if request.post? && @user.content_partner.update_attributes(params[:content_partner])
      @user.content_partner.log_completed_step!('transfer_overview')
      redirect_to(:action => 'transfer_upload') unless params[:save_type] && params[:save_type] == 'save'
    end
  end

  def transfer_upload
    @page_header = I18n.t("transfer_schema_upload")
    @user = User.find(current_user.id)
    @user.content_partner.log_seen_step!('transfer_upload')

    if request.post? && @user.content_partner.update_attributes(params[:content_partner])
      @user.content_partner.log_completed_step!('transfer_upload')

      unless params[:save_type] && params[:save_type] == 'save'
        if @user.content_partner.ready_for_agreement?
          redirect_to(resources_url)
        else
          redirect_to(:action => 'dashboard')
        end
      end
    end
  end
end
