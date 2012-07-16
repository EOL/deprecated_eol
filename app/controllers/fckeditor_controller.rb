require 'fileutils'
require 'tmpdir'

class FckeditorController < ActionController::Base

  @@fck_mime_types ||= [
    "image/jpg",
    "image/jpeg",
    "image/pjpeg",
    "image/gif",
    "image/png",
    "application/x-shockwave-flash"
  ]

  def upload_file
    begin
      load_file_from_params
      log @new_file
      if mime_types_ok(@ftype) && new_file_path = copy_tmp_file(@new_file)
        final_file_path = ContentServer.image_cache_path(new_file_path, :orig)
      else
        raise 'couldnt upload file'
      end
    rescue => e
      @errorNumber = 110 if @errorNumber.nil?
    end

    render :text => %Q'
      <script>
         window.parent.OnUploadCompleted(#{@errorNumber}, "#{final_file_path}");
      </script>'
  end

  def upload
    self.upload_file
  end

  include ActionView::Helpers::SanitizeHelper

  def check_spelling
    require 'cgi'
    require 'fckeditor_spell_check'

    @original_text = params[:textinputs] ? params[:textinputs].first : ''
    plain_text = strip_tags(CGI.unescape(@original_text))
    @words = FckeditorSpellCheck.check_spelling(plain_text)

    render :file => "#{Fckeditor::PLUGIN_VIEWS_PATH}/fckeditor/spell_check.rhtml"
  end

  #################################################################################
  #
  private

  def load_file_from_params
    @new_file = check_file(params[:NewFile])
    @fck_url  = "/"
    @ftype     = @new_file.content_type.strip.downcase
    log_upload
  end

  ##############################################################################
  # Chek if mime type is included in the @@fck_mime_types
  #
  def mime_types_ok(ftype)
    mime_type_ok = @@fck_mime_types.include?(ftype) ? true : false
    if mime_type_ok
      @errorNumber = 0
    else
      @errorNumber = 202
      raise_mime_type_and_show_msg(ftype)
    end
    mime_type_ok
  end

  ##############################################################################
  # Raise and exception, log the msg error and show msg
  #
  def raise_mime_type_and_show_msg(ftype)
    msg = "#{ftype} is invalid MIME type"
    puts msg;
    raise msg;
    log msg
  end

  ##############################################################################
  # Copy tmp file to current_directory_path/tmp_file.original_filename
  #
  def copy_tmp_file(tmp_file)
    path = $LOGO_UPLOAD_PATH + tmp_file.original_filename
    File.open("public/" + path, "wb", 0664) do |fp|
      FileUtils.copy_stream(tmp_file, fp)
    end
    ContentServer.upload_content(path, request.port.to_s)
  end

  ##############################################################################
  # Puts a messgae info in the current log, only if RAILS_ENV is 'development'
  #
  def log(str)
    RAILS_DEFAULT_LOGGER.info str if RAILS_ENV == 'development'
  end

  ##############################################################################
  # Puts some data in the current log
  #
  def log_upload
    log "FCKEDITOR - #{params[:NewFile]}"
    # log "FCKEDITOR - UPLOAD_FOLDER: #{UPLOAD_FOLDER}"
    # log "FCKEDITOR - #{File.expand_path(RAILS_ROOT)}/public#{UPLOAD_FOLDER}/" +
    #     "#{@new_file.original_filename}"

  end

  ##############################################################################
  # check that the file is a tempfile object
  #
  def check_file(file)
    log "FCKEDITOR ---- CLASS OF UPLOAD OBJECT: #{file.class}"

    unless file.class.to_s == "Tempfile" || file.class.to_s == "StringIO"
      @errorNumber = 403
      throw Exception.new
    end
    file
  end
end
