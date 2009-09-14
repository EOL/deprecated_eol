module TaxaHelper

  # These start out display:none, so we can show them only after JS behaviours have been applied.
  # which: a string to be used to create the ID of the anchor: try 'comment', 'tagging', or 'curator'.
  # where: the URL you want the anchor to reference (used by JS to create an Ajax request).
  def popup_link(which, where, options = {})
    html_options = {
      :id => "large-image-#{which}-button-popup-link", :class => 'popup-link', :style => 'display:none;'
    }.merge(options)
    link_to '<span style="display:block;width:24px;height:25px;"></span>', where, html_options
  end

  def vetted_id_class(data_object)
    return case data_object.vetted_id
      when Vetted.unknown.id   then 'unknown-background-image'
      when Vetted.untrusted.id then 'untrusted-background-image'
      when Vetted.trusted.id   then 'trusted-background-image'
      else nil
    end
  end
    
  def we_have_css_for_kingdom?(kingdom)
    return false if kingdom.nil?
    return $KINGDOM_IDs.include?(kingdom.id.to_s)
  end
  
  def show_next_image_page_button
    if params[:image_page].blank?
      show_next_image_page_button = @taxon_concept.more_images 
    else
      image_page = (params[:image_page] ||= 1).to_i
      start       = $MAX_IMAGES_PER_PAGE * (image_page - 1)
      last        = start + $MAX_IMAGES_PER_PAGE - 1
      show_next_image_page_button = (@taxon_concept.images.length > (last + 1))
    end
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
           "', video_trusted:'" + escape_javascript(video.vetted_id.to_s) +
           "', video_url:'"     + escape_javascript("#{video.video_url}" || video.object_url || '') +
           "', data_object_id:'"+ escape_javascript(video.id.to_s) +
           "', taxon_concept_id:'#{taxon_concept_id}'}"
  end
  
  def paginate_results(search)
    pages = search.total_pages
    current_page = search.current_page
    html  = Builder::XmlMarkup.new
    html.div(:class => 'serp_pagination') do

      html << deactivatable_link('&lt;&lt;&nbsp;Prev',
                                 :href => search_by_page_href(current_page - 1),
                                 :deactivated => current_page == 1)
      
      lower_bound = current_page - 10
      lower_bound = 1 if lower_bound < 1
      upper_bound = current_page + 10
      upper_bound = pages if upper_bound > pages

      (lower_bound..upper_bound).each do |page|
        html.span(:class => 'pg_link') {
          html << deactivatable_link(page.to_s,
                                     :href => search_by_page_href(page),
                                     :deactivated => current_page == page)
        }
      end
      
      html << deactivatable_link('Next&nbsp;&gt;&gt;',
                                 :href => search_by_page_href(current_page + 1),
                                 :deactivated => current_page == pages)

    end
  end

# A *little* weird to have private methods in the helper, but these really help clean up the code for the methods
# that are public, and, indeed, should never be called outside of this class.
private
  
  def search_by_page_href(link_page)
    lparams = params.clone
    lparams["page"] = link_page
    lparams.delete("action")
    "/search/?#{lparams.to_query}"
  end
  
  def deactivatable_link(text, options)
    deactivated = options.delete(:deactivated)
    raise "Cannot create deactivatable link without href option" unless options.has_key? :href
    raise "Cannot create deactivatable link without deactivated option" if deactivated.nil?
    html = Builder::XmlMarkup.new
    if deactivated
      html << text
    else
      html.a(options) { html << text } # Block style, so that the text is handled 'raw', rather than interpolated
    end
    html << '&nbsp;'
    return html.to_s # TODO - without the to_s, this injects some weird markup (<respond_to?:to_str>true</..etc>)
                     # With this to_s, that problem is solved, but this STILL injects <to_s/>  ... WTF?
  end

  def show_next_image_page_button
    if params[:image_page].blank?
      show_next_image_page_button = @taxon_concept.more_images 
    else
      image_page = (params[:image_page] ||= 1).to_i
      start       = $MAX_IMAGES_PER_PAGE * (image_page - 1)
      last        = start + $MAX_IMAGES_PER_PAGE - 1
      show_next_image_page_button = (@taxon_concept.images.length > (last + 1))
    end
  end
  
end
