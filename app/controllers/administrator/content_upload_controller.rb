class Administrator::ContentUploadController < AdminController

  layout 'deprecated/left_menu'

  before_filter :set_layout_variables

  before_filter :restrict_to_admins

  def index
    @page_title = I18n.t("uploaded_content")
    @content_uploads = ContentUpload.paginate(order: 'created_at desc', page: params[:page])
  end

  def edit
    @page_title = I18n.t("edit_upload")
    @content_upload = ContentUpload.find(params[:id])
  end

  def update
    @content_upload = ContentUpload.find(params[:id])
    if @content_upload.update_attributes(params[:content_upload])
      flash[:notice] = I18n.t(:the_content_was_updated)
      redirect_to(action: 'index', status: :moved_permanently)
    else
      render action: 'edit'
    end
  end

  def new
    @page_title = I18n.t("new_upload")
    @content_upload = ContentUpload.new
  end

  def create
    @content_upload = ContentUpload.create(params[:content_upload])
    if @content_upload.save
      @content_upload.update_attributes(user_id: current_user.id, attachment_extension: File.extname(@content_upload.attachment_file_name))
      upload_file(@content_upload)
      flash[:notice] = I18n.t(:the_file_was_uploaded)
      redirect_to(action: 'index', status: :moved_permanently)
    else
      render action: 'new'
    end
  end

private

  def upload_file(content_upload)
    # TODO - would this be easier with request#host_with_port ?
    # Update 2/23/14 - request.ip is returning 127.0.0.1, so we should be really careful and make
    # sure we understand what request.anything will give. We need to be certain this it the
    # app server **IP**
    ip_with_port = EOL::Server.ip_address.dup
    ip_with_port += ":" + request.port.to_s unless ip_with_port.match(/:[0-9]+$/)
    parameters = 'function=admin_upload&file_path=http://' + ip_with_port + $CONTENT_UPLOAD_PATH + content_upload.id.to_s + "."  + content_upload.attachment_file_name.split(".")[-1]
    response = EOLWebService.call(parameters: parameters)
    if response.blank?
      EOL.log("ERROR: Content upload service failed: #{$WEB_SERVICE_BASE_URL}#{parameters}",
        prefix: "*")
    else
      response = Hash.from_xml(response)
      if response["response"].key? "file_path"
        file_path = response["response"]["file_path"]
        content_upload.update_column(:attachment_cache_url, file_path) # store new url to file on content server
      end
      if response["response"].key? "error"
        error = response["response"]["error"]
        EOL.log("ERROR: #{error}: #{$WEB_SERVICE_BASE_URL}#{parameters}",
          prefix: "*")
      end
    end
  end

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
