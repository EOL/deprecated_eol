module FileDownloadHelper
  
  EXPIRATION_TIME = 2.weeks
  
  def upload_file (id, local_file_path, local_file_url)
    where = local_file_path
    error = ""
    begin
      hash = ContentServer.upload_data_search_file(local_file_url, id)
      if hash.nil?
        return {error: "Couldn't create the required file"}
      else
        uploaded_file_url = hash[:response]
        error = hash[:error]
        if uploaded_file_url
          where = uploaded_file_url
          update_attributes(hosted_file_url: Rails.configuration.hosted_dataset_path + where)
          return {error: nil}
        end  
      end
    rescue => e
      # TODO: This is an important one to catch!
      Rails.logger.error "ERROR: could not upload #{where} to Content Server: #{e.message}"
    end
    return {error: error}
  end
  
  def downloadable?
    complete? && hosted_file_url && ! ( expired? || row_count.blank? || row_count == 0)
  end

  def expired?
    Time.now > expires_at
  end

  def hosted_file_exists?
    !! (hosted_file_url && EOLWebService.url_accepted?(hosted_file_url))
  end

  def complete?
    failed_at.nil? && ! completed_at.nil?
  end

  def expires_at
    completed_at + EXPIRATION_TIME
  end
  
  def get_headers(rows)
    col_heads = Set.new
    rows.each do |row|
      col_heads.merge(row.keys)
    end
    col_heads
  end
  
  def csv_builder(csv, col_heads, rows)
    csv << col_heads
    rows.each do |row|
      csv << col_heads.inject([]) { |a, v| a << row[v] } # A little magic to sort the values...
    end
  end
  
end