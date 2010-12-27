# This is, quite simply, a class to round-robin our asset servers, so that their load is equally distributed (in theory).
class ContentServer

  @@next = 0 # This reults in the second entry being used first.  I'm okay with that; it's arbitrary where we begin.
  @@cache_url_re = /(\d{4})(\d{2})(\d{2})(\d{2})(\d+)/

  def self.next
    @@next += 1 
    @@next = 0 if @@next > $CONTENT_SERVERS.length - 1
    return $CONTENT_SERVERS[@@next]
  end

  def self.agent_logo_path(url, size = nil)
    return self.blank if url.blank?
    logo_size = (size == "large") ? "_large.png" : "_small.png"
    "#{self.next}#{$CONTENT_SERVER_AGENT_LOGOS_PATH}#{url}#{logo_size}"
  end

  def self.cache_path(cache_url, subdir = $CONTENT_SERVER_CONTENT_PATH)
    (self.next + subdir + self.cache_url_to_path(cache_url))
  end

  def self.cache_url_to_path(cache_url)
    new_path = cache_url.to_s.gsub(@@cache_url_re, "/\\1/\\2/\\3/\\4/\\5")
  end

  def self.blank
    "/images/blank.gif"
  end

  def self.uploaded_content_url(url, ext)
    return self.blank if url.blank?
    (self.next + $CONTENT_SERVER_CONTENT_PATH + self.cache_url_to_path(url) + ext)
  end

end
