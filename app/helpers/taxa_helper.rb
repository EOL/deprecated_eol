module TaxaHelper

  # These start out display:none, so we can show them only after JS behaviours have been applied.
  # which: a string to be used to create the ID of the anchor: try 'comment', 'tagging', or 'curator'.
  # where: the URL you want the anchor to reference (used by JS to create an Ajax request).
  def popup_link(which, where)
    link_to '<span style="display:block;width:24px;height:25px;"></span>', where, 
            :id => "large-image-#{which}-button-popup-link", :class => 'popup-link', :style => 'display:none;'
  end
  
  def link_text(text,link="",params={})
    eol_return_linked_text(text,link,params)
  end
    
  def agent_partial(original_agents, params={})
    return '' if original_agents.nil? or original_agents.blank?
    # I am going to cache values (in memory), since there is often a LOT of repetition, here.
    # Note that I don't bother caching non-linked values, since that's just one variable, anyway.
    @@cached_links ||= {}
    params[:linked] = true if params[:linked].nil?
    params[:only_first] ||= false
    params[:show_link_icon] = true if params[:show_link_icon].nil?
    agents = original_agents.clone # so we can be destructive.
    agents = [agents] unless agents.class == Array # Allows us to pass in a single agent, if needed.
    agents = [agents[0]] if params[:only_first]
    agent_list = agents.collect do |agent|
      params[:linked] ? link_text(hh(agent.full_name), agent.homepage, :show_link_icon => params[:show_link_icon]).strip : hh(agent.full_name)        
    end.join(', ') # I know this looks awkward, but I'm making it more readable.  : )
    agent_list += ', et al.' if params[:only_first] and original_agents.length > 1
    return agent_list
  end

  def agent_icons_partial(original_agents,params={})
    return '' if original_agents.nil? or original_agents.blank?
    params[:linked] = true if params[:linked].nil?
    params[:show_text_if_no_icon] ||= false
    params[:only_show_col_icon] ||= false
    params[:normal_icon] ||= false
    params[:separator] ||= "&nbsp;"
    params[:last_separator] ||= params[:separator]
    params[:taxon] ||= false
    
    is_default_col = false
    if(params[:taxon] != false && !params[:taxon].col_entry.nil?)
      is_default_col = true
    end
    
    agents = original_agents.clone # so we can be destructive.
    agents = [agents] unless agents.class == Array # Allows us to pass in a single agent, if needed.
    
    output_html = Array.new
    
    agents.each do |agent|
      logo_size=(agent == Agent.catalogue_of_life ? "large" : "small") # CoL gets their logo big     
      if agent.logo_cache_url.blank? 
        output_html << agent_partial(agent,params) if params[:show_text_if_no_icon] 
      else
        url = agent.homepage.strip || ''
        if params[:only_show_col_icon] && !is_default_col # if we are only asked to show the logo if it's COL and the current agent is *not* COL, then show text
          output_html << agent_partial(agent,params)
        else
          if params[:linked] and not url.blank?
            text = agent_logo(agent,logo_size,params)
            output_html << '<a onclick="JavaScript:external_link(\'' + CGI::escape(url) + '\',true,' + $USE_EXTERNAL_LINK_POPUPS.to_s + ');return false;" href="#">' + text + '</a>'          
          else
            output_html << agent_logo(agent,logo_size,params)
          end
        end
      end
      
    end
    
    if output_html.size > 1 && params[:last_separator] != params[:separator]
      # stich the last two elements together with the "last separator" column before joining if there is more than 1 element and the last separator is different
      output_html[output_html.size-2] += params[:last_separator] + output_html.pop
		end

    return output_html.compact.join(params[:separator]) 

  end
    
  def video_hash(video,taxon_concept_id='')
    # TODO: (something of a big change, since it means altering the JS)
    #       Note that this won't handle the agent_partial stuff; handle separately:
    # return video.to_json(:methods => :video_url)
    if taxon_concept_id.blank? # grab the first taxon concept ID from the video object if we didn't just pass it in
      taxon_concepts=video.taxa_names_taxon_concept_ids
      taxon_concept_id = taxon_concepts[0][:taxon_concept_id] unless taxon_concepts.blank?
    end
    return "{author: '"        + escape_javascript(agent_partial(video.authors)) +
           "', nameString: '"   + escape_javascript(video.scientific_name) +
           "', collection: '"   + escape_javascript(agent_partial(video.sources)) +
           "', location: '"     + escape_javascript(video.location || '') +
           "', info_url: '"     + escape_javascript(video.source_url || '') +
           "', field_notes: '"  + escape_javascript(video.description || '') +
           "', license_text: '" + escape_javascript(video.license_text || '') +
           "', license_logo: '" + escape_javascript(video.license_logo || '') +
           "', license_link: '" + escape_javascript(video.license_url || '') +
           "', title:'"         + escape_javascript(video.object_title) +
           "', video_type:'"    + escape_javascript(video.media_type) +
           "', video_url:'"     + escape_javascript("#{video.video_url}" || video.object_url || '') +
           "', data_object_id:'"+ escape_javascript(video.id.to_s) +
           "', taxon_concept_id:'" + escape_javascript(taxon_concept_id) + 
           "'}"
  end

  # Note that I change strong to b, 'cause strong appears to be overridden in our CSS.  Hrmph.
  def allow_some_html(text)
    ['i', 'b', 'strong', 'em', 'blockquote', 'small'].each do |tag|
      text.gsub!(/&lt;(\/?)#{tag}&gt;/i, "<\\1#{tag.gsub(/strong/, 'b')}>")
    end
    text.gsub!(/\r\n/, '<br/>')
    return text
  end

end
