class ContactsController < ApplicationController

  layout 'basic'
  
  def index
    redirect_to contact_us_path
  end
  
  # GET /contacts/new and named route /contact_us
  def new
    @contact = Contact.new
    @contact.ip_address = request.remote_ip
    @contact.referred_page = params[:referred_page] || request.referer
    if logged_in?
      @contact.user_id = current_user.id
      @contact.name = current_user.full_name
      @contact.email = current_user.email
    end
    @subject = params[:subject] ? ContactSubject.find(:first,
      joins: "JOIN translated_contact_subjects tcs ON (contact_subjects.id=tcs.contact_subject_id)",
      conditions: "tcs.title like '#{params[:subject]}%'") : nil
  end

  # POST /contacts
  def create
    @contact = Contact.new(params[:contact])

    failed_to_create_contact and return unless @contact.valid? && verify_recaptcha

    @contact.comments << "\n\n#{user_url(current_user)}" if logged_in?
    if @contact.save
      # Note: Contact message is emailed to recipients on after_create, see Contact model
      Notifier.contact_us_auto_response(@contact).deliver
      flash[:notice] = I18n.t('contacts.notices.message_sent')
      redirect_to contact_us_path
    else
      # Unlikely we'll get here since we already checked validation above, but just in case.
      failed_to_create_contact
    end
  end

private

  def failed_to_create_contact
    flash.now[:error] = I18n.t('contacts.errors.message_not_sent')
    flash.now[:error] << I18n.t(:recaptcha_incorrect_error_with_anchor,
                                recaptcha_anchor: 'recaptcha_widget_div') unless verify_recaptcha
    page_title([:contacts, :new])
    render :new
  end

  def contact_subjects
    @contact_subjects ||= ContactSubject.find_all_by_active(true)
  end
  helper_method :contact_subjects

end

