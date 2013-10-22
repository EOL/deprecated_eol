class DataSearchFile < ActiveRecord::Base

  attr_accessible :from, :known_uri, :known_uri_id, :language, :language_id, :q, :sort, :to, :uri, :user, :user_id, :completed_at,
    :hosted_file_url
  attr_accessor :results

  belongs_to :user
  belongs_to :language
  belongs_to :known_uri

  LIMIT = 500

  def build_file
    return send_notification if hosted_file_exists?
    write_file(get_data)
    upload_file
    if hosted_file_exists?
      send_notification
      update_attributes(completed_at: Time.now.utc)
    end
  end

  def csv
    rows = get_data
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

  def filename
    return @filename if @filename
    @filename = "something.csv"
    if known_uri
      @filename = "#{known_uri.name}"
      @filename += "_f#{from}" unless from.blank?
      @filename += "-#{to}" unless to.blank?
      @filename += "_by_#{sort}" unless sort.blank?
      @filename += ".csv"
    else
      # TODO - handle other filename cases (ie: when there is no attribute known_uri) as needed. Right now, that's impossible.
    end
    @filename
  end

  private

  def local_file_path
    $DATA_SEARCH_FILE_DIRECTORY.sub(/:id/, id.to_s)
  end

  def local_file_url
    ip_with_port = $IP_ADDRESS_OF_SERVER.dup
    "http://" + ip_with_port + $DATA_SEARCH_FILE_PATH.sub(/:id/, id.to_s)
  end

  def get_data
    # TODO - really, we shouldn't use pagination at all, here. But that's a huge change. For now, use big limits.
    @results = TaxonData.search(querystring: q, attribute: uri, from: from, to: to,
      sort: sort, per_page: LIMIT, :for_download => true) # TODO - if we KEEP pagination, make this value more sane (and put page back in).
    # TODO - handle the case where results are empty.
    rows = []
    DataPointUri.assign_bulk_metadata(@results, user.language)
    @results.each do |data_point_uri|
      rows << data_point_uri.to_hash(user.language)
    end
    rows
  end

  def get_headers(rows)
    col_heads = Set.new
    rows.each do |row|
      col_heads.merge(row.keys)
    end
    col_heads
  end

  def write_file(rows)
    col_heads = get_headers(rows)
    CSV.open(local_file_path, 'wb') do |csv|
      csv_builder(csv, col_heads, rows)
    end
  end

  def upload_file
    if uploaded_file_url = ContentServer.upload_data_search_file(local_file_url, id)
      update_attributes(hosted_file_url: $HOSTED_DATASET_PATH + uploaded_file_url)
    end
  end

  def csv_builder(csv, col_heads, rows)
    csv << col_heads
    rows.each do |row|
      csv << col_heads.inject([]) { |a, v| a << row[v] } # A little magic to sort the values...
    end
    if @results.total_entries > LIMIT
      csv << [ Sanitize.clean(I18n.t(:data_beta_search_limit, count: LIMIT)) ]
    end
  end

  def send_notification
    if user
      old_locale = I18n.locale
      begin
        I18n.locale = user.language.iso_639_1
        comment = Comment.create!(parent: user,
                                  body: I18n.t('data_search_files.file_ready_for_download', download_url: hosted_file_url, known_uri_label: known_uri.name),
                                  user: user) # TODO - maybe this should be "from" someone specific?
        user.comments << comment
        force_immediate_notification_of(comment)
      ensure
        I18n.locale = old_locale
      end
    else
      # TODO - not sure how we're going to do this. Session cookie to look for it each time page loads?  Woof.
    end
  end

  def force_immediate_notification_of(comment)
    PendingNotification.create!(:user_id => user_id,
                                :notification_frequency_id => NotificationFrequency.immediately.id,
                                :target => comment,
                                :reason => 'auto_email_after_curation')
    Resque.enqueue(PrepareAndSendNotifications)
  rescue => e
    # Do nothing (for now)...
  end

end
