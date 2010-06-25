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
    
    self.create_feed(feed_items, :title => options[:title], :link => feed_link)
  end
  
  
  def create_feed(feed_items, options = {})
    options[:link] ||= root_url
    options[:title] ||= 'Latest Images, Text and Comments'
    
    feed_items.sort! {|x,y| y['created_at'] <=> x['created_at']}
    feed_items = feed_items[0..@@maximum_feed_entries]
    
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
      
      e.title = "#{hash['scientific_name']}"
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








  def partner_curation()    
    agent_id = params[:agent_id] || nil
    year = params[:year] || nil
    month = params[:month] || nil

    partner = Agent.find(agent_id, :select => [:full_name])
    partner_fullname = partner.full_name

    latest_harvest_id = Agent.latest_harvest_event_id(agent_id)        
    arr_dataobject_ids = HarvestEvent.data_object_ids_from_harvest(latest_harvest_id)

    do_detail = DataObject.get_object_cache_url(arr_dataobject_ids)

    #arr = User.curated_data_object_ids(arr_dataobject_ids,agent_id)
    arr = User.curated_data_object_ids(arr_dataobject_ids, year, month, @agent_id)
      arr_dataobject_ids = arr[0]
      arr_user_ids = arr[1]

    if(arr_dataobject_ids.length == 0) then 
      arr_dataobject_ids = [1] #no data objects
    end

    arr_obj_tc_id = DataObject.tc_ids_from_do_ids(arr_dataobject_ids);
    partner_curated_objects = User.curated_data_objects(arr_dataobject_ids, year, month, 0, "feed")

    feed_items = {}

    ctr=0
    partner_curated_objects.each do |rec|
      ctr=ctr+1
      if(arr_obj_tc_id["datatype#{rec.data_object_id}"])
        if(arr_obj_tc_id["datatype#{rec.data_object_id}"]=="text") then
          do_type = "Text"
        else
          do_type = "Image"
        end
      end

      concept = TaxonConcept.find(arr_obj_tc_id["#{rec.data_object_id}"])
      tc_name = concept.quick_scientific_name()

      t = rec.updated_at
      updated_at =  t.strftime("%d-%b-%Y")  
      updated_at += t.strftime(" at %I:%M%p")          

      temp = [ "curator"   => rec.given_name + " " + rec.family_name,  
               "activity"  => rec.code || nil, 
               "do_type"   => do_type || nil,
               "tc_id"     => arr_obj_tc_id["#{rec.data_object_id}"] || nil,
               "do_id"     => rec.data_object_id || nil,
               "tc_name"   => ctr.to_s + ". " + tc_name || nil,
               "updated_at"       => updated_at || nil,
               "object_cache_url" =>  do_detail["#{rec.data_object_id}"] || nil
             ]
      if(ctr == 1)
        feed_items = temp
      else
        feed_items += temp
      end
    end        

    feed = Atom::Feed.new do |f|
      f.updated = Time.now
      f.links << Atom::Link.new(:href => "www.eol.org")
      f.title = partner_fullname + " curation activity "
      feed_items.each do |hash|
        f.entries << partner_feed_entry(hash)
      end
    end
    render :text => feed.to_xml
  end

  def partner_feed_entry(hash)
    Atom::Entry.new do |e|   
      if(hash['do_type']=="Text") then
        e.title = hash['tc_name']
        e.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => hash['tc_id'],:text_id => hash['do_id']))
      else
        e.title = hash['tc_name']
        e.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => hash['tc_id'],:image_id => hash['do_id']))
      end
      e.updated = hash['updated_at']

      content = hash['do_type'] + " was changed to '" + hash['activity'] + "' by " + hash['curator'] + " last " + hash['updated_at'] + " " + "<br/><br/>"

      if hash['do_type'] == 'Image'
        content = "<img src='#{DataObject.image_cache_path(hash['object_cache_url'],'small')}'/></a><br/>" + content
      end


      #content += "" + "<br/><br/>"      
      e.content = Atom::Content::Html.new(content)
    end
  end


end
