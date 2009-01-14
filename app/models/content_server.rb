# This is, quite simply, a class to round-robin our asset servers, so that their load is equally distributed (in theory).
class ContentServer
  @@next = 0 # This reults in the second entry being used first.  I'm okay with that; it's arbitrary where we begin.
  def self.next
    @@next += 1 
    @@next = 0 if @@next > $CONTENT_SERVERS.length - 1
    return $CONTENT_SERVERS[@@next]
  end
end
