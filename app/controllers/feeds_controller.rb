class FeedsController < ApplicationController
  
  #/feeds/images/25 or texts or comments or all
  before_filter :set_session_hierarchy_variable
  caches_page :all, :images, :texts, :comments, :expires_in => 2.minutes
  @@maximum_feed_entries = 50
  
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
    if options[:type] != :comments
      feed_items += DataObject.for_feeds(options[:type], taxon_concept.id, @@maximum_feed_entries)
    end
    if options[:type] == :comments
      feed_items += Comment.for_feeds(:comments, taxon_concept_id, @@maximum_feed_entries)
    end
    
    self.create_feed(feed_items, :type => options[:type], :id => taxon_concept_id, :title => options[:title], :link => feed_link)
  end
  
  
  def create_feed(feed_items, options = {})
    @feed_url = url_for(:controller => 'feeds', :action => options[:type], :id => options[:id])
    @feed_link = options[:link] || root_url
    @feed_title = options[:title] || 'Latest Images, Text and Comments'
    
    
    feed_items.sort! {|x,y| y['created_at'] <=> x['created_at']}
    feed_items = feed_items[0..@@maximum_feed_entries]
    
    @feed_entries = []
    feed_items.each do |hash|
      @feed_entries << feed_entry(hash)
    end
    
    respond_to do |format|
      format.atom { render :template => '/feeds/feed_template', :layout => false }
    end
  end
  
  def feed_entry(hash)
    entry = { :id => '', :title => '', :link => '', :content => '', :updated => '' }
    
    link_type_id = :comment_id
    if hash['data_type_label'] == 'Image'
      link_type_id = :image_id
    elsif hash['data_type_label'] == 'Text'
      link_type_id = :text_id
    end
    
    entry[:title] = hash['scientific_name']
    entry[:link] = url_for(:controller => :taxa, :action => :show, :id => hash['taxon_concept_id'], link_type_id => hash['id'])
    #entry[:id] = hash['guid']
    entry[:id] = entry[:link]
    entry[:updated] = hash['created_at']
    
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
    entry[:content] = content
    return entry
  end








  def partner_curation()
    agent_id = params[:agent_id] || nil
    year = params[:year] || nil
    month = params[:month] || nil
    
    agent = Agent.find(agent_id)
    latest_harvest_event = agent.latest_harvest_event
    
    partner_curated_objects = latest_harvest_event.curated_data_objects(:year => year, :month => month)
    
    feed_items = []
    partner_curated_objects.each do |row|
      updated_time = Time.parse(row['updated_at'])
      updated_at = updated_time.strftime("%d-%b-%Y") + " at " + updated_time.strftime("%I:%M%p")
      
      action_comment = nil
      if ['inappropriate', 'untrusted'].include?(row['action_code'])
        lower_time = (updated_time - 10.seconds).mysql_timestamp
        upper_time = (updated_time + 10.seconds).mysql_timestamp
        result = Comment.find_by_sql("SELECT c.* FROM comments c WHERE created_at BETWEEN '#{lower_time}' AND '#{upper_time}' AND parent_type='DataObject' AND user_id=#{row['curator_user_id']} LIMIT 1")
        action_comment = result[0] unless result.empty?
      end
      
      feed_items << {  "curator"          => (row['given_name'] + " " + row['family_name']).strip,
                       "curator_user_id"  => row['curator_user_id'],
                       "action_comment"   => action_comment,
                       "activity"         => row['action_code'],
                       "do_type"          => row['data_type_label'],
                       "tc_id"            => row['taxon_concept_id'],
                       "do_id"            => row['data_object_id'],
                       "tc_name"          => row['scientific_name'],
                       "updated_at"       => updated_at,
                       "object_cache_url" => row['object_cache_url'] || nil,
                       "source_url"       => row['source_url'] || nil }
    end
    
    @feed_url = url_for(:controller => 'feeds', :action => 'partner_curation', :agent_id => agent_id, :month => month, :year => year)
    @feed_link = "http://www.eol.org"
    @feed_title = agent.full_name + " curation activity"
    
    @feed_entries = []
    feed_items.each do |hash|
      @feed_entries << partner_feed_entry(hash)
    end
    
    respond_to do |format|
      format.atom { render :template => '/feeds/feed_template', :layout => false }
    end
  end

  def partner_feed_entry(hash)
    entry = { :id => '', :title => '', :link => '', :content => '', :updated => '' }
    
    entry[:title] = hash['tc_name']
    entry[:updated] = hash['updated_at']
    
    if(hash['do_type']=="Text") then
      entry[:link] = url_for(:controller => :taxa, :action => :show, :id => hash['tc_id'], :text_id => hash['do_id'])
    else
      entry[:link] = url_for(:controller => :taxa, :action => :show, :id => hash['tc_id'], :image_id => hash['do_id'])
    end
    entry[:id] = entry[:link]
    
    curator_link = url_for(:controller => 'account', :action => 'show', :id => hash['curator_user_id'], :only_path => false)
    content = hash['do_type'] + " was changed to '" + hash['activity'] + "' by <a href='#{curator_link}'>" + hash['curator'] + "</a> last " + hash['updated_at'] + " <br/>"
    if hash['action_comment']
      content += "Comment: " + hash['action_comment'].body + "<br/>"
    end
    
    if hash['do_type'] == 'Image'
      content = "<img src='#{DataObject.image_cache_path(hash['object_cache_url'],'small')}'/><br/>" + content
    end
    
    # Will insert a link to a Wikipedia article
    # TODO - looking for oldid in the link isn't robust enough to determine the object is a Wikipedia article
    temp = hash['source_url']
    result = temp.split(/oldid=\s?/)
    revision_id = result[1] 
    if(revision_id) then
      content += "Revision ID: <a target='wikipedia' href='#{hash['source_url']}'/>#{revision_id}</a>"
    end
    
    entry[:content] = content
    return entry
  end
end
