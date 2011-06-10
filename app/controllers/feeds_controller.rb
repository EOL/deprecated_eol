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

  def feed_entry(comment_or_data_object)
    entry = { :id => '', :title => '', :link => '', :content => '', :updated => '' }
    if comment_or_data_object.class == DataObject
      data_object = comment_or_data_object
      entry[:title] = data_object.first_concept_name
      entry[:link] = url_for(:controller => 'data_objects', :action => data_object.id, :only_path => false)
      entry[:id] = entry[:link]
      entry[:updated] = data_object.created_at

      entry[:content] = data_object.description + "<br/><br/>"

      # include image
      if data_object.is_image?
        entry[:content] = "<img src='#{data_object.thumb_or_object}'/></a><br/>" + entry[:content]
      end
      entry[:content] += "<b>License</b>: #{data_object.license.title}<br/>" unless data_object.license.blank?

      # include attribution
      data_object.agents_data_objects.each do |ado|
        entry[:content] += "<b>#{ado.agent_role.label.capitalize}</b>: #{ado.agent.full_name}<br/>"
      end
      return entry
    else
      comment_hash = comment_or_data_object
      entry[:title] = comment_hash['scientific_name']
      entry[:link] = url_for(:controller => :taxa, :action => :show, :id => comment_hash['taxon_concept_id'], :comment_id => comment_hash['id'])
      entry[:id] = entry[:link]
      entry[:updated] = comment_hash['created_at']
      entry[:content] = comment_hash['description']
      return entry
    end
  end








  def partner_curation()
    user_id = params[:user_id] || nil
    year = params[:year] || nil
    month = params[:month] || nil

    user = User.find(user_id)
    latest_harvest_event = user.content_partner.resources.first.latest_harvest_event rescue nil

    curator_activity_logs = latest_harvest_event.curated_data_objects(:year => year, :month => month)

    @feed_url = url_for(:controller => 'feeds', :action => 'partner_curation', :user_id => user_id, :month => month, :year => year)
    @feed_link = "http://www.eol.org"
    @feed_title = user.full_name + " curation activity"

    @feed_entries = []
    curator_activity_logs.each do |ah|
      @feed_entries << partner_feed_entry(ah)
    end

    respond_to do |format|
      format.atom { render :template => '/feeds/feed_template', :layout => false }
    end
  end

  def partner_feed_entry(curator_activity_log)
    entry = { :id => '', :title => '', :link => '', :content => '', :updated => '' }

    entry[:title] = curator_activity_log.data_object.first_concept_name
    entry[:updated] = curator_activity_log.updated_at
    entry[:link] = url_for(:controller => 'data_objects', :action => curator_activity_log.data_object.id, :only_path => false)
    entry[:id] = entry[:link]

    curator_link = url_for(:controller => 'account', :action => 'show', :id => curator_activity_log.user_id, :only_path => false)
    date_string = curator_activity_log.updated_at.strftime("%d-%b-%Y") + " at " + curator_activity_log.updated_at.strftime("%I:%M%p")
    content = "#{curator_activity_log.activity.name.capitalize} by <a href='#{curator_link}'>#{curator_activity_log.user.full_name}</a> last #{date_string}<br/>"
    if curator_activity_log.comment
      content += "Comment: #{curator_activity_log.comment.body}<br/>"
    end

    if curator_activity_log.data_object.is_image?
      content = "<img src='#{DataObject.image_cache_path(curator_activity_log.data_object.object_cache_url, 'small')}'/><br/>" + content
    end

    # Will insert a link to a Wikipedia article
    # TODO - looking for oldid in the link isn't robust enough to determine the object is a Wikipedia article
    result = curator_activity_log.data_object.source_url.split(/oldid=\s?/)
    if revision_id = result[1]
      content += "Revision ID: <a target='wikipedia' href='#{curator_activity_log.data_object.source_url}'/>#{revision_id}</a>"
    end

    entry[:content] = content
    return entry
  end
end
