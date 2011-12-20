class ContactsController < ApplicationController
  helper :application 
  layout 'v2/sessions'

  def index
    @contact = Contact.new
    if logged_in?
      @contact.name = current_user.username
      @contact.email = current_user.email
    end
    @list = load_areas
  end

  def create
    @contact = Contact.new(params[:contact])
    failed_to_create_request and return unless @contact.valid? && verify_recaptcha    
    if @contact.save
      send_verification_email
      @list = load_areas
      @contact = Contact.new
      flash.now[:notice] = I18n.t(:contact_us_request_sent)
      render :action => :index, :layout => 'v2/sessions'
    else
      failed_to_create_request and return
    end
  end

  def load_areas
    areas = ContactSubject.find(:all)
    list = []
    areas.each {|r| list.concat([[r.title,r.id]])}
    list
  end

  def failed_to_create_request
    flash.now[:error] = I18n.t(:contact_us_request_failed)
    @list = load_areas
    render :action => :index, :layout => 'v2/sessions'
  end

  def send_verification_email
    if logged_in?
      @contact.comments = @contact.comments + '\n' + request.env["HTTP_HOST"] + user_path(current_user)
    end
    Notifier.deliver_contact_us_message(@contact)
  end

end

