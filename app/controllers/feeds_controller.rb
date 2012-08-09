class FeedsController < ApplicationController

  #/feeds/images/25 or texts or comments or all
  caches_page :all, :images, :texts, :comments, :expires_in => 2.minutes
  @@maximum_feed_entries = 50

  # TODO - Really, this should probably be in an "ActivityLogsController", not here.
  # Given an id and a type (class name), find the page where that item should be, and what page of activity it's
  # actually on, if not the first.
  def find
    case params[:type]
    when "Comment"
      comment = Comment.find(params[:id])
      parent  = comment.parent
      # Obnoxiously, taxon concepts only have 10 comments per page and must be handled exceptionally to the default
      # of 20:
      page = find_index(parent, 'Comment', params[:id], comment.parent_type == 'TaxonConcept' ? 10 : 20)
      case comment.parent_type
      when 'TaxonConcept'
        redirect_to add_hash_to_path(taxon_update_path(parent, :page => page), 'Comment', params[:id])
      when 'DataObject'
        redirect_to add_hash_to_path(data_object_path(DataObject.latest_published_version_of(parent.id), :page => page), 'Comment', params[:id])
      when 'Community'
        redirect_to add_hash_to_path(community_newsfeed_path(parent, :page => page), 'Comment', params[:id])
      when 'Collection'
        redirect_to add_hash_to_path(filtered_collection_path(parent, 'newsfeed', :page => page), 'Comment', params[:id])
      when 'User'
        redirect_to add_hash_to_path(user_newsfeed_path(parent, :page => page), 'Comment', params[:id])
      else
        raise "Unknown comment parent type: #{comment.parent_type}"
      end
    when "CuratorActivityLog"
      cal = CuratorActivityLog.find(params[:id])
      # There are only two kinds: taxon and dato...
      if source = cal.taxon_concept
        page = find_index(source, 'CuratorActivityLog', params[:id], 10)
        redirect_to add_hash_to_path(taxon_update_path(cal.taxon_concept, :page => page), 'CuratorActivityLog', params[:id])
      else # Dato:
        source = cal.data_object
        page = find_index(source, 'CuratorActivityLog', params[:id], 20)
        redirect_to add_hash_to_path(data_object_path(source, :page => page), 'CuratorActivityLog', params[:id])
      end
    when "CommunityActivityLog"
      cal = CommunityActivityLog.find(params[:id])
      source = cal.community
      page = find_index(source, 'CommunityActivityLog', params[:id], 20)
      redirect_to add_hash_to_path(community_path(source, :page => page), 'CommunityActivityLog', params[:id])
    when "CollectionActivityLog"
      cal = CollectionActivityLog.find(params[:id])
      source = cal.collection
      page = find_index(source, 'CollectionActivityLog', params[:id], 20)
      redirect_to add_hash_to_path(collection_newsfeed_path(source, :page => page), 'CollectionActivityLog', params[:id])
    when "UsersDataObject"
      # This one is somewhat questionable: do we want to go to the user's page or to the taxon concpet page where it
      # was added?  Or to the data object itself?  I suppose that last one makes the most sense, soooo:
      udo = UsersDataObject.find(params[:id])
      source = DataObject.latest_published_version_of(udo.data_object_id)
      page = find_index(source, 'UsersDataObject', params[:id], 20)
      redirect_to add_hash_to_path(data_object_path(source, :page => page), 'UsersDataObject', params[:id])
    else
      raise "Unknown activity log type: #{params[:type]}"
    end
  end

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

  def partner_curation()
    content_partner_id = params[:content_partner_id] || nil
    year = params[:year] || nil
    month = params[:month] || nil

    content_partner = ContentPartner.find(content_partner_id)
    latest_harvest_event = content_partner.resources.first.latest_harvest_event rescue nil

    curator_activity_logs = latest_harvest_event.curated_data_objects(:year => year, :month => month)

    @feed_url = url_for(:controller => 'feeds', :action => 'partner_curation', :content_partner_id => content_partner_id, :month => month, :year => year)
    @feed_link = "http://www.eol.org"
    @feed_title = content_partner.full_name + " curation activity"

    @feed_entries = []
    curator_activity_logs.each do |ah|
      @feed_entries << partner_feed_entry(ah)
    end

    respond_to do |format|
      format.atom { render :template => '/feeds/feed_template', :layout => false }
    end
  end


private

  def lookup_content(options = {})
    taxon_concept_id = params[:id] || nil
    options[:type] ||= :all
    options[:title] ||= 'Latest Images, Text and Comments'
    taxon_concept = TaxonConcept.find(taxon_concept_id)

    feed_link = url_for(:controller => :taxa, :action => :show, :id => taxon_concept.id)
    options[:title] += " for #{taxon_concept.quick_scientific_name(:normal)}"

    feed_items = []
    if options[:type] != :comments
      feed_items += DataObject.for_feeds(options[:type], taxon_concept.id, @@maximum_feed_entries)
    end
    if options[:type] == :comments
      feed_items += Comment.for_feeds(:comments, taxon_concept_id, @@maximum_feed_entries)
    end

    create_feed(feed_items, :type => options[:type], :id => taxon_concept_id, :title => options[:title], :link => feed_link)
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

  def partner_feed_entry(curator_activity_log)
    entry = { :id => '', :title => '', :link => '', :content => '', :updated => '' }

    entry[:title] = curator_activity_log.data_object.first_concept_name
    entry[:updated] = curator_activity_log.updated_at
    entry[:link] = url_for(:controller => :data_objects, :action => :show, :id => curator_activity_log.data_object.id, :only_path => false)
    entry[:id] = entry[:link]

    curator_link = url_for(:controller => :users, :action => :show, :id => curator_activity_log.user_id, :only_path => false)
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

  def find_index(source, type, id, per_page)
    # Just check the first page, first:
    log = source.activity_log(:per_page => per_page, :page => 1)
    return 1 unless log.select {|i| i['activity_log_type'] == type && i['activity_log_id'] == id.to_i}.blank?
    # Not there, keep going:
    page = 1
    while page < 100
      log = source.activity_log(:per_page => 100, :page => page)
      if i = log.find_index {|i| i['activity_log_type'] == type && i['activity_log_id'] == id.to_i}
        return (((page - 1) * 100 + i + 1) / per_page.to_f).ceil
      end
      page += 1
    end
    return 1 # this will cause the right page to load, without the comment.  ...It's lost to time.
  end

  def add_hash_to_path(path, type, id)
    path += "##{(params[:reply] && params[:reply] != 'false') ? 'reply-to-' : ''}#{type}-#{id}"
  end
end
