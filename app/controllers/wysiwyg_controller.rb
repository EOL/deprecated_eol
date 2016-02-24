class WysiwygController < ApplicationController

  @@valid_mime_types ||= [
    "image/jpg",
    "image/jpeg",
    "image/pjpeg",
    "image/gif",
    "image/png",
    "application/x-shockwave-flash"
  ]

  def upload_image
    @func_num = params[:CKEditorFuncNum]
    @ck_editor = params[:CKEditor]
    if params.include?(:upload)
      temp_file = params[:upload]
      mime_type = temp_file.content_type.strip.downcase
      if temp_file.class.to_s == "Tempfile" || temp_file.class.to_s == "StringIO" || !valid_mime_type(mime_type)
        raise "Could not process image upload"
      end

      if new_file_path = copy_temp_file(temp_file)
        @final_file_path = DataObject.image_cache_path(new_file_path, :orig)
      end
    end
    if @final_file_path.blank?
      raise "Could not process image upload"
    end
    render layout: false
  end

  private

  def valid_mime_type(mime_type)
    !!@@valid_mime_types.include?(mime_type)
  end

  def copy_temp_file(temp_file)
    EOL.log_call
    path = Rails.configuration.logo_uploads.relative_path + temp_file.original_filename
    File.open("public/" + path, "wb", 0664) do |fp|
      FileUtils.copy_stream(temp_file, fp)
    end
    resp = ContentServer.upload_content(path, request.port.to_s)
    resp.has_key?(:response) ? resp[:response] : resp
  end
end
