class DataSearchFile < ActiveRecord::Base

  attr_accessible :from, :known_uri, :known_uri_id, :language, :language_id, :q, :sort, :to, :uri, :user, :user_id,
    :completed_at, :hosted_file_url, :row_count, :unit_uri, :taxon_concept_id
  attr_accessor :results

  belongs_to :user
  belongs_to :language
  belongs_to :known_uri
  belongs_to :taxon_concept

  PER_PAGE = 500 # Number of results we feel confident to process at one time (ie: one query for each)
  PAGE_LIMIT = 2000 # Maximum number of "pages" of data to allow in one file.
  LIMIT = PAGE_LIMIT * PER_PAGE
  EXPIRATION_TIME = 2.weeks

  def build_file
    unless hosted_file_exists?
      write_file
      upload_file
      # The user may delete the download before it has finished (if it's hung,
      # the workers are busy or its just taking a very long time). If so,
      # we should not email them when the process has finished
      if hosted_file_exists? && instance_still_exists?
        send_completion_email
      end
      update_attributes(completed_at: Time.now.utc)
    end
  end

  def csv(options = {})
    rows = get_data(options)
    col_heads = get_headers(rows)
    CSV.generate do |csv|
      csv_builder(csv, col_heads, rows)
    end
  end

  def hosted_file_exists?
    !! (hosted_file_url && EOLWebService.url_accepted?(hosted_file_url))
  end

  def complete?
    ! completed_at.nil?
  end

  def instance_still_exists?
    !! DataSearchFile.find_by_id(id)
  end

  def downloadable?
    complete? && hosted_file_url && ! ( expired? || row_count.blank? || row_count == 0)
  end

  def expired?
    Time.now > expires_at
  end

  def expires_at
    completed_at + EXPIRATION_TIME
  end

  def local_file_url
    "http://" + EOL::Server.ip_address + Rails.configuration.data_search_file_rel_path.sub(/:id/, id.to_s)
  end

  def unit_known_uri
    KnownUri.find_by_uri(unit_uri)
  end

  def from_as_data_point
    DataPointUri.new(object: from, unit_of_measure_known_uri_id: unit_known_uri ? unit_known_uri.id : nil)
  end

  def to_as_data_point
    DataPointUri.new(object: to, unit_of_measure_known_uri_id: unit_known_uri ? unit_known_uri.id : nil)
  end

  private

  def local_file_path
    Rails.configuration.data_search_file_full_path.sub(/:id/, id.to_s)
  end

  def get_data(options = {})
    # TODO - we should also check to see if the job has been canceled.
    rows = []
    page = 1
    # TODO - handle the case where results are empty. ...or at least write a test to verify the behavior is okay/expected.
    search_parameters = { querystring: q, attribute: uri, min_value: from, max_value: to, sort: sort,
                          per_page: PER_PAGE, for_download: true, taxon_concept: taxon_concept, unit: unit_uri }
    results = TaxonData.search(search_parameters)
    # TODO - we should probably add a "hidden" column to the file and allow admins/master curators to see those
    # rows, (as long as they are marked as hidden). For now, though, let's just remove the rows:
    results = results.delete_if { |r| r.hidden? }
    begin # Always do this at least once...
      break unless DataSearchFile.exists?(self) # Someone canceled the job.
      DataPointUri.assign_bulk_metadata(results, user.language)
      DataPointUri.assign_bulk_references(results, user.language)
      results.each do |data_point_uri|
        # TODO - really, I think we should move this to TaxonData.search. :\
        # Skip taxon concepts that have been superceded!
        next if data_point_uri.taxon_concept &&
          data_point_uri.taxon_concept.superceded?
        # TODO - Whoa! Even when I ran “dpu.to_hash[some_val]”, even though it
        # had loaded the whole thing, it looked up taxon_concept names. …WTFH?!?
        rows << data_point_uri.to_hash(user.language)
      end
      if (page * PER_PAGE < results.total_entries)
        page += 1
        results = TaxonData.search(search_parameters.merge(page: page))
      else
        break
      end
    end until ((page - 1) * PER_PAGE >= results.total_entries) || page > PAGE_LIMIT
    @overflow = true if page > PAGE_LIMIT
    rows
  end

  def get_headers(rows)
    col_heads = Set.new
    rows.each do |row|
      col_heads.merge(row.keys)
    end
    col_heads
  end

  # TODO - we /might/ want to add the utf-8 BOM here to ease opening the file for users of Excel. q.v.:
  # http://stackoverflow.com/questions/9886705/how-to-write-bom-marker-to-a-file-in-ruby
  def write_file
    rows = get_data
    col_heads = get_headers(rows)
    CSV.open(local_file_path, 'wb') do |csv|
      csv_builder(csv, col_heads, rows)
    end
    update_attributes(row_count: rows.count)
  end

  def upload_file
    where = local_file_path
    begin
      if uploaded_file_url = ContentServer.upload_data_search_file(where, id)
        where = uploaded_file_url
        update_attributes(hosted_file_url: Rails.configuration.hosted_dataset_path + where)
      else
        # TODO: we REALLY need to do something here!
      end
    rescue => e
      # TODO: This is an important one to catch!
      Rails.logger.error "ERROR: could not upload #{where} to Content Server: #{e.message}"
    end
  end

  def csv_builder(csv, col_heads, rows)
    csv << col_heads
    rows.each do |row|
      csv << col_heads.inject([]) { |a, v| a << row[v] } # A little magic to sort the values...
    end
    if @overflow
      csv << [ Sanitize.clean(I18n.t(:data_search_limit, count: LIMIT)) ]
    end
  end

  def send_completion_email
    RecentActivityMailer.data_search_file_download_ready(self).deliver
  end

end
