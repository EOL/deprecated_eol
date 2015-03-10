class Taxa::DataController < TaxaController

  helper DataSearchHelper # Because we include one of its partials.

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :load_data
  before_filter :load_glossary  
  
  GENDER = 1
  LIFE_STAGE = 0

  # GET /pages/:taxon_id/data/index
  def index
    @assistive_section_header = I18n.t(:assistive_data_header)
    @recently_used = KnownUri.where(['uri IN (?)', session[:rec_uris]]) if session[:rec_uris]
    @selected_data_point_uri_id = params.delete(:data_point_uri_id)
    if params[:toc_id].nil?
        @toc_id = 'ranges' if @data_point_uris.blank? && !@range_data.blank?
    else
      @toc_id = params[:toc_id]
      @toc_id = nil unless @toc_id == 'other' || @categories.detect{ |toc| toc.id.to_s == @toc_id }
    end
    
    @querystring = ''
    @sort = ''
    current_user.log_activity(:viewed_taxon_concept_data, taxon_concept_id: @taxon_concept.id)
    @jsonld = EOL::Api::Traits::V1_0.prepare_hash(@taxon_concept,
                                                  data: @taxon_data)
  end

  # GET /pages/:taxon_id/data/about
  def about
    @toc_id = 'about'
  end

  # GET /pages/:taxon_id/data/glossary
  def glossary
    @toc_id = 'glossary'
  end

  # GET /pages/:taxon_id/data/ranges
  def ranges
    @toc_id = 'ranges'
  end

protected

  def meta_description
    @taxon_data.topics
    translation_vars = scoped_variables_for_translations.dup
    translation_vars[:topics] = @taxon_data.topics.join("; ") unless @taxon_data.topics.empty?
    I18n.t("meta_description#{translation_vars[:topics] ? '_with_topics' : '_no_data'}", translation_vars)
  end

  def load_data
    # Sad that we need to load all of this for the about and glossary tabs, but TODO - we can cache this, later:
    @taxon_data = @taxon_page.data
    @range_data = @taxon_data.ranges_of_values
    @data_point_uris = sort_data(@taxon_page.data.get_data)
    @categories = TocItem.for_uris(current_language).select{ |toc| @taxon_data.categories.include?(toc) }
    @include_other_category = @data_point_uris &&
      @data_point_uris.detect { |d| d.predicate_known_uri.nil? || d.predicate_known_uri.toc_items.blank? }
    @units_for_select = KnownUri.default_units_for_form_select
  end
  
  #0 for life stage and 1 for gender
  def sort_data (results)
    stat_positions = get_position(results.data_point_uris)
    results.data_point_uris.sort do |a, b|
      if a.context_labels[GENDER].to_s == b.context_labels[GENDER].to_s && a.context_labels[LIFE_STAGE].to_s == b.context_labels[LIFE_STAGE].to_s
        if !a.statistical_method.to_s.blank? && !b.statistical_method.to_s.blank?          
          stat_positions[a.statistical_method.to_s] <=> stat_positions[b.statistical_method.to_s]
        else          
          a.statistical_method.to_s.blank? ? 1 : -1
        end
      elsif a.context_labels[GENDER].to_s == b.context_labels[GENDER].to_s
        sort_life_stage(a,b)
      else        
        (a.context_labels[GENDER].to_s.blank? ? 255.chr : a.context_labels[GENDER].to_s) <=> (b.context_labels[GENDER].to_s.blank? ? 255.chr : b.context_labels[GENDER].to_s)  
      end
    end
  end

  def sort_life_stage (a,b)    
    if !a.context_labels[LIFE_STAGE].to_s.blank? && !b.context_labels[LIFE_STAGE].to_s.blank?      
      a.context_labels[LIFE_STAGE].to_s <=> b.context_labels[LIFE_STAGE].to_s
    else      
      a.context_labels[LIFE_STAGE].to_s.blank? ? 1 : -1
    end    
  end
  
  def get_position(data_point_uris)
    Hash[KnownUri.where(uri: data_point_uris.map { |d| d.statistical_method.to_s }).
      select([:uri, :position]).map {|k| [k.uri, k.position] }]
  end
  
  def load_glossary
    @glossary_terms = @data_point_uris ?
      ( @data_point_uris.select{ |dp| ! dp.predicate_known_uri.blank? }.collect(&:predicate_known_uri) +
        @data_point_uris.select{ |dp| ! dp.object_known_uri.blank? }.collect(&:object_known_uri) +
        @data_point_uris.select{ |dp| ! dp.unit_of_measure_known_uri.blank? }.collect(&:unit_of_measure_known_uri) +
        @range_data.collect{ |r| r[:attribute] }).compact.uniq
      : []
  end

end
