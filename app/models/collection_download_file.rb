class CollectionDownloadFile < ActiveRecord::Base
  include FileDownloadHelper
  
  belongs_to :user
  belongs_to :collection
  
  def build_file(data_point_uris, user_lang)
    unless hosted_file_exists?
      write_file(data_point_uris, user_lang)
      debugger
      response = upload_file(id, local_file_path, local_file_url)
      debugger
      send_completion_email
      debugger
      if response[:error].blank?
        if hosted_file_exists? && instance_still_exists?
          send_completion_email
        end
        update_attributes(completed_at: Time.now.utc)
      else
        update_attributes(failed_at: Time.now.utc, error: response[:error])
      end
    end
  end
  
  def local_file_path
    Rails.configuration.collection_download_file_full_path.sub(/:id/, id.to_s)
  end

  def local_file_url
    "http://" + EOL::Server.ip_address + Rails.configuration.collection_download_file_rel_path.sub(/:id/, id.to_s)
  end
  
  private
  
  def get_data(data_point_uris, user_lang)
    rows = []    
    data_point_uris.each do |data_point_uri|
      next if data_point_uri.taxon_concept &&
        data_point_uri.taxon_concept.superceded?
      rows << data_point_uri.to_hash(user_lang)
    end
    rows
  end

  def write_file(data_point_uris, user_lang)
    rows = get_data(data_point_uris, user_lang)
    col_heads = get_headers(rows)
    CSV.open(local_file_path, 'wb') do |csv|
      csv_builder(csv, col_heads, rows)
    end
    update_attributes(row_count: rows.count)
  end
  
  def instance_still_exists?
    !! CollectionDownloadFile.find_by_id(id)
  end
  
  def send_completion_email
    RecentActivityMailer.collection_file_download_ready(self).deliver
  end
  
end
