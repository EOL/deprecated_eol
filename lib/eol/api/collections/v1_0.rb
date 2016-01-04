module EOL
  module Api
    module Collections
      class V1_0 < EOL::Api::MethodVersion
        VERSION = '1.0'
        BRIEF_DESCRIPTION = Proc.new { I18n.t(:returns_all_metadata_about_a_particular_collection) }
        DESCRIPTION = Proc.new {
          # updates/stats tab of page 1 - Animalia
          updates_url = statistics_taxon_updates_url(1)
          I18n.t(:api_docs_collections_description, :richness_url => view_context.link_to(updates_url, updates_url) ) }
        PARAMETERS = Proc.new {
          [
            EOL::Api::DocumentationParameter.new(
              :name => 'id',
              :type => Integer,
              :required => true,
              :test_value => (Collection.where(:name => 'EOL Group on Flickr').first || Collection.last).id ),
            EOL::Api::DocumentationParameter.new(
              :name => 'page',
              :type => Integer,
              :default => 1 ),
            EOL::Api::DocumentationParameter.new(
              :name => 'per_page',
              :type => Integer,
              :values => (0..500),
              :default => 50 ),
            EOL::Api::DocumentationParameter.new(
              :name => 'filter',
              :type => String,
              :values => [ 'articles', 'collections', 'communities', 'images', 'sounds', 'taxa', 'users', 'video' ] ),
            EOL::Api::DocumentationParameter.new(
              :name => 'sort_by',
              :type => String,
              :values => SortStyle.all.map{ |ss| ss.name(:en).downcase.gsub(' ', '_') rescue nil }.compact,
              :default => SortStyle.newest.name(:en).downcase.gsub(' ', '_') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'sort_field',
              :type => String,
              :notes => I18n.t('collection_api_sort_field_notes')),
            EOL::Api::DocumentationParameter.new(
              :name => 'cache_ttl',
              :type => Integer,
              :notes => I18n.t('api_cache_time_to_live_parameter')),  
              EOL::Api::DocumentationParameter.new(
                name: "language",
                type: String,
                values: Language.approved_languages.collect(&:iso_639_1),
                default: "en",
                notes: I18n.t(:limits_the_returned_to_a_specific_language))
          ] }

        def self.call(params={})
          validate_and_normalize_input_parameters!(params)
          I18n.locale = params[:language] unless params[:language].blank?
          if params[:sort_by].class == String && ss = SortStyle.find_by_translated(:name, params[:sort_by].titleize)
            params[:sort_by] = ss
          else
            params[:sort_by] = collection.default_sort_style
          end

          begin
            collection = Collection.find(params[:id], :include => [ :sort_style ])
          rescue
            raise EOL::Exceptions::ApiException.new("Unknown collection id \"#{params[:id]}\"")
          end

          prepare_hash(collection, params)
        end

        def self.prepare_hash(collection, params={})
          facet_counts = EOL::Solr::CollectionItems.get_facet_counts(collection.id)
          collection_results = collection.items_from_solr(:facet_type => params[:filter], :page => params[:page], :per_page => params[:per_page],
            :sort_by => params[:sort_by], :view_style => ViewStyle.list, :sort_field => params[:sort_field])
          collection_items = collection_results.map { |i| i['instance'] }
          CollectionItem.preload_associations(collection_items, :refs)

          return_hash = {}
          return_hash['name'] = collection.name
          return_hash['description'] = collection.description
          return_hash['logo_url'] = collection.logo_cache_url.blank? ? nil : collection.logo_url
          return_hash['created'] = collection.created_at
          return_hash['modified'] = collection.updated_at
          return_hash['total_items'] = collection_results.total_entries

          return_hash['item_types'] = []
          ['TaxonConcept', 'Text', 'Video', 'Image', 'Sound', 'Community', 'User', 'Collection'].each do |facet|
            return_hash['item_types'] << { 'item_type' => facet, 'item_count' => facet_counts[facet] || 0 }
          end

          return_hash['collection_items'] = []
          collection_results.each do |r|
            ci = r['instance']
            next if ci.nil?
            item_hash = {
              'name' => r['title'],
              'object_type' => ci.collected_item_type,
              'object_id' => ci.collected_item_id,
              'title' => ci.name,
              'created' => ci.created_at,
              'updated' => ci.updated_at,
              'annotation' => ci.annotation,
              'sort_field' => ci.sort_field
            }

            if collection.show_references?
              item_hash['references'] = []
              ci.refs.each do |ref|
                item_hash['references'] << { 'reference' => ref.full_reference }
              end
            end

            case ci.collected_item_type
            when 'TaxonConcept'
              item_hash['richness_score'] = sprintf("%.5f", r['richness_score'] * 100.00).to_f
              # item_hash['taxonRank'] = ci.collected_item.entry.rank.label.firstcap unless ci.collected_item.entry.rank.nil?
            when 'DataObject'
              item_hash['data_rating'] = r['data_rating']
              item_hash['object_guid'] = ci.collected_item.guid
              item_hash['object_type'] = ci.collected_item.data_type.simple_type
              if ci.collected_item.is_image?
                item_hash['source'] = ci.collected_item.thumb_or_object(:orig)
              end
            end
            return_hash['collection_items'] << item_hash
          end
          return return_hash
        end
      end
    end
  end
end
