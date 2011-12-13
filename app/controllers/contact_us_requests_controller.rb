class ContactUsRequestsController < ApplicationController
  helper :application 
  layout 'v2/sessions'

  def index
    @request = ContactUsRequest.new
    @list = load_areas
  end

  def create
    @request = ContactUsRequest.new(params[:contact_us_request])
    failed_to_create_request and return unless @request.valid? && verify_recaptcha    
    if @request.save
      send_verification_email
      @list = load_areas
      flash.now[:notice] = "Request Sent"
      render :action => :index, :layout => 'v2/sessions'
    else
      failed_to_create_request and return
    end
  end

  def load_areas
    areas = TopicArea.find(:all)
    list = []
    areas.each {|r| list.concat([[r.label,r.id]])}
    list
  end

  def failed_to_create_request
    flash.now[:error] = "Your contact us request cannot be sent"
    @list = load_areas
    render :action => :index, :layout => 'v2/sessions'
  end

  def send_verification_email
    #Notifier.deliver_user_message(@request, @request, @request.comment)

  end

end

