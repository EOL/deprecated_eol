class Link < LoggingModel
  has_many :activity_logs

  def self.find_or_create(key)
    if link = Link.find_by_url(key)
      return link
    else
      # Doing this with raw sql to override the LoggingModel's defauly of using INSERT DELAYED
      Link.connection.execute(ActiveRecord::Base.sanitize_sql_array(['INSERT INTO links (url) VALUES (?)', key]))
      return Link.find_by_url(key)
    end
  end
end
