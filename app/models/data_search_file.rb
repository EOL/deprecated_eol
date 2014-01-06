class DataSearchFile < ActiveRecord::Base

  attr_accessible :from, :known_uri, :known_uri_id, :language, :language_id, :q, :sort, :to, :uri, :user, :user_id,
    :completed_at, :hosted_file_url, :row_count
  attr_accessor :results

  belongs_to :user
  belongs_to :language
  belongs_to :known_uri

  PER_PAGE = 2000 # Number of results we feel confident to process at one time (ie: one query for each)
  PAGE_LIMIT = 5 # Maximum number of "pages" of data to allow in one file.
  LIMIT = PAGE_LIMIT * PER_PAGE

  def build_file
    unless hosted_file_exists?
      write_file
      upload_file
      # The user may delete the download before it has finished (if it's hung,
      # the workers are busy or its just taking a very long time). If so,
      # we should not email them when the process has finished
      if hosted_file_exists? && instance_still_exists?
        send_completion_email
        update_attributes(completed_at: Time.now.utc)
      end
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
    hosted_file_url && EOLWebService.url_accepted?(hosted_file_url)
  end

  def complete?
    ! completed_at.nil?
  end

  def instance_still_exists?
    !! DataSearchFile.find_by_id(id)
  end

  def filename
    return @filename if @filename
    @filename = "something.csv"
    if known_uri
      @filename = "#{known_uri.name}"
      @filename += "_f#{from}" unless from.blank?
      @filename += "-#{to}" unless to.blank?
      @filename += "_sort_#{sort}" unless sort.blank?
      @filename += ".csv"
    else
      # TODO - handle other filename cases (ie: when there is no attribute known_uri) as needed. Right now, that's impossible.
    end
    @filename
  end

  def local_file_url
    ip_with_port = $IP_ADDRESS_OF_SERVER.dup
    "http://" + ip_with_port + Rails.configuration.data_search_file_rel_path.sub(/:id/, id.to_s)
  end

  private

  def local_file_path
    Rails.configuration.data_search_file_full_path.sub(/:id/, id.to_s)
  end

  def get_data(options = {})
    # NOTE - for testing on staging:
    # q = '' ; uri = 'http://iobis.org/minphosphate' ; from = nil ; to = nil ; sort = nil ; PER_PAGE = 12 ; options = {} ; user = User.first
    rows = []
    page = 1
    # TODO - handle the case where results are empty. ...or at least write a test to verify the behavior is okay/expected.
    results = TaxonData.search(querystring: q, attribute: uri, from: from, to: to, sort: sort,
                               per_page: PER_PAGE, for_download: true)
    # TODO - we should also check to see if the job has been canceled.
    until (page * PER_PAGE >= results.total_entries) || page > PAGE_LIMIT
      DataPointUri.assign_bulk_metadata(results, user.language)
      DataPointUri.assign_bulk_references(results, user.language)
      results.each do |data_point_uri|
        rows << data_point_uri.to_hash(user.language)
      end
      if results.total_pages < results.current_page
        page += 1
        results = TaxonData.search(querystring: q, attribute: uri, from: from, to: to, sort: sort,
                                   page: page, per_page: PER_PAGE, for_download: true)
      end
    end
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
    if uploaded_file_url = ContentServer.upload_data_search_file(local_file_url, id)
      update_attributes(hosted_file_url: (Rails.configuration.local_services ? uploaded_file_url : (Rails.configuration.hosted_dataset_path + uploaded_file_url)))
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
