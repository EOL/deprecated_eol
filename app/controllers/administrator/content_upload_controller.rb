class Administrator::ContentUploadController < AdminController

  access_control :DEFAULT => 'Administrator - Site CMS'
  layout 'admin'
   
  def index
    @page_title = 'Uploaded Content'
    @content_uploads=ContentUpload.paginate(:order=>'created_at desc',:page => params[:page])
  end
   
  def edit
    @page_title = 'Edit Upload' 
    @content_upload=ContentUpload.find(params[:id])
  end

  def update
    @content_upload = ContentUpload.find(params[:id])  
    if @content_upload.update_attributes(params[:content_upload])
      flash[:notice]="The content was updated."
      redirect_to(:action=>'index')
    else
      render :action=>'edit'
    end
  end

  def new
    @page_title = 'New Upload'
    @content_upload=ContentUpload.new
  end

  def create
    @content_upload=ContentUpload.create(params[:content_upload])
    if @content_upload.save
      @content_upload.update_attributes(:user_id=>current_user.id,:attachment_extension=>File.extname(@content_upload.attachment_file_name))
      upload_file(@content_upload)
      flash[:notice]="The file was uploaded."
      redirect_to(:action=>'index')
    else
      render :action=>'new'
    end
  end

private

  def upload_file(content_upload)
    parameters='function=upload_content&file_path=http://' + $IP_ADDRESS_OF_SERVER + ":" + request.port.to_s + $CONTENT_UPLOAD_PATH + content_upload.id.to_s + "."  + content_upload.attachment_file_name.split(".")[-1]
    response=EOLWebService.call(:parameters=>parameters)
    if response.blank?
      ErrorLog.create(:url  => $WEB_SERVICE_BASE_URL, :exception_name  => "content upload service failed") if $ERROR_LOGGING
    else
      response = Hash.from_xml(response)
      if response["response"].key? "file_path"
        file_path = response["response"]["file_path"]
        content_upload.update_attribute(:attachment_cache_url,file_path) # store new url to file on content server      
      end
      if response["response"].key? "error"
        error = response["response"]["error"]
        ErrorLog.create(:url=>$WEB_SERVICE_BASE_URL,:exception_name=>error,:backtrace=>parameters) if $ERROR_LOGGING
      end
    end
  end

end
