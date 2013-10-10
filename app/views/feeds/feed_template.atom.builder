atom_feed(:url => @feed_url, :id => @feed_url, :root_url => @feed_link) do |f|
  f.updated Time.now
  f.title @feed_title
  @feed_entries.each do |feed_entry|
    f.entry(feed_entry, :url => feed_entry[:link], :id => feed_entry[:id]) do |e|
      e.title feed_entry[:title]
      e.content feed_entry[:content], :type => 'html'
      e.updated feed_entry[:updated]
    end
  end
end
