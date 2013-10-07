class DataFile # TODO - I think we should make this an ActiveRecord::Base model. That'll act as a log of the files we've created,
  # and it's not too expensive.

  LIMIT = 100

  attr_reader :q, :uri, :from, :to, :sort, :user, :known_uri

  def initialize(args)
    @q = args[:q]
    @uri = args[:uri]
    @from = args[:from]
    @to = args[:to]
    @sort = args[:sort]
    @user = args[:user]
    @known_uri = args[:known_uri]
    build_file
  end

  private

  def build_file
    puts "   #build_file"
    return send_notification if file_exists?
    write_file(get_data)
    send_notification
  end

  def file_name
    return @filename if @filename
    path = "something.csv"
    if args[:known_uri]
      path = "#{args[:known_uri].name}.csv" 
      path += "_f#{@from}" unless @from.blank?
      path += "-#{@to}" unless @to.blank?
      path += "_by_#{@sort}" unless @sort.blank?
      # TODO - handle other filename cases as needed
    end
    @filename = Rails.root.join("public", path)
  end

  def file_exists?
    return false # TODO
  end

  def get_data
    # TODO - really, we shouldn't use pagination at all, here.
    results = TaxonData.search(querystring: @q, attribute: @uri, from: @from, to: @to,
      sort: @sort, per_page: LIMIT) # TODO - if we KEEP pagination, make this value more sane (and put page back in).
    puts "   results = #{results.count}"
    # TODO - handle the case where results are empty.
    rows = []
    results.each do |data_point_uri|
      rows << data_point_uri.to_hash(@user.language)
    end
    puts "   .. got data"
    rows
  end

  def get_headers(rows)
    col_heads = Set.new
    rows.each do |row|
      col_heads.merge(row.keys)
    end
    puts "   .. made heads (#{col_heads.to_a.join(', ')})"
    col_heads
  end

  def write_file(rows)
    col_heads = get_headers(rows)
    CSV.open(file_name) do |csv|
      csv << col_heads
      rows.each do |row|
        csv << col_heads.inject([]) { |a, v| a << row[v] } # A little magic to sort the values...
      end
    end
    puts "  .. file created."
  end

  def send_notification
    if @user
      old_locale = I18n.locale
      begin
        I18n.locale = @user.language.iso_639_1
        comment = Comment.create!(parent: @user,
                                  body: I18n.t(:file_ready_for_download, file: 'TODO', query: @q),
                                  user: @user) # TODO - maybe this should be "from" someone specific?
        @user.comments << comment
        force_immediate_notification_of(comment)
      ensure
        I18n.locale = old_locale
      end
    else
      # TODO - not sure how we're going to do this. ...Again, storing this as ActiveRecord::Base w/b helpful.
    end
  end

  def force_immediate_notification_of(comment)
    begin
      PendingNotification.create!(:user_id => user_id,
                                  :notification_frequency_id => NotificationFrequency.immediately.id,
                                  :target => comment,
                                  :reason => 'auto_email_after_curation')
      Resque.enqueue(PrepareAndSendNotifications)
      puts "  .. notification enqueued."
    rescue => e
      # Do nothing (for now)...
    end
  end

end
