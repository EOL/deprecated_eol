class FeedsController < ApplicationController
  
  #/feeds/images/25 or texts or comments or all
  before_filter :set_session_hierarchy_variable
  caches_page :all, :images, :texts, :comments, :expires_in => 2.minutes
  
  def all
    lookup_content(:type => :all)
  end
  
  def images
    lookup_content(:type => :images, :title => 'Latest Images')
  end

  def text
    lookup_content(:type => :text, :title => 'Latest Text')
  end
  
  def comments
    lookup_content(:type => :comments, :title => 'Latest Comments')
  end
  
  def lookup_content(options = {})
    taxon_concept_id = params[:id] || nil
    options[:type] ||= :all
    options[:title] ||= 'Latest Images, Text and Comments'
    begin
      taxon_concept = TaxonConcept.find(taxon_concept_id)
    rescue
      render_404
      return false
    end
    
    feed_link = url_for(:controller => :taxa, :action => :show, :id => taxon_concept.id)
    options[:title] += " for #{taxon_concept.quick_scientific_name(:normal, @session_hierarchy)}"
    
    feed_items = []
    feed_items += DataObject.for_feeds(options[:type], taxon_concept.id) if options[:type] != :comments
    feed_items += Comment.for_feeds(:comments, taxon_concept_id) if options[:type] == :comments
    
    self.create_feed(feed_items, :title => options[:title], :link => feed_link)
  end
  
  
  def create_feed(feed_items, options = {})
    options[:link] ||= root_url
    options[:title] ||= 'Latest Images, Text and Comments'
    
    feed_items.sort! {|x,y| y['created_at'] <=> x['created_at']}
    feed_items = feed_items[0..100]
    
    feed = Atom::Feed.new do |f|
      f.updated = Time.now
      f.links << Atom::Link.new(:href => options[:link])
      f.title = options[:title]
      
      feed_items.each do |hash|
        f.entries << feed_entry(hash)
      end
    end
    render :text => feed.to_xml
  end
  
  def feed_entry(hash)
    Atom::Entry.new do |e|
      link_type_id = :comment_id
      if hash['data_type_label'] == 'Image'
        link_type_id = :image_id
      elsif hash['data_type_label'] == 'Text'
        link_type_id = :text_id
      end
      
      e.title = "New #{hash['data_type_label'].downcase} for #{hash['scientific_name']}"
      e.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => hash['taxon_concept_id'], link_type_id => hash['id']))
      e.updated = hash['created_at']
      
      content = hash['description'] + "<br/><br/>"
      if hash['data_type_label'] == 'Image'
        content = "<img src='#{DataObject.image_cache_path(hash['object_cache_url'])}'/></a><br/>" + content
      end
      
      content += "<b>License</b>: #{hash['license_label']}<br/>" unless hash['license_label'].blank?
      
      # add attribution
      unless hash["agents"].nil?
        for agent in hash["agents"]
          content += "<b>#{agent["role"].capitalize}</b>: #{agent["full_name"]}<br/>"
        end
      end
      e.content = Atom::Content::Html.new(content)
    end
  end
end
