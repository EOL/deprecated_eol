module EOL
  module Solr
    class SiteSearchCoreRebuilder
      attr_reader :solr_api
      attr_reader :objects_to_send
      
      def initialize(solr_api)
        @solr_api = solr_api
        @objects_to_send = []
      end
      
      def begin_rebuild(optimize = true)
        @solr_api.delete_all_documents
        add_taxa_names
        @solr_api.optimize if optimize
      end
      
      def add_taxa_names
        start, max_id = TaxonConcept.connection.execute("SELECT MIN(id) as min, MAX(id) as max FROM taxon_concepts").fetch_row
        limit = 10000
        i = start.dup.to_i
        while i <= max_id.to_i
          @objects_to_send = []
          lookup_names(i, limit);
          @solr_api.send_attributes(@objects_to_send) unless @objects_to_send.blank?
          i += limit
        end
      end
      
      def lookup_names(start, limit)
        max = start + limit
        taxon_concepts = TaxonConcept.find(:all, :conditions => "id BETWEEN #{start} AND #{max}",
          :include => { :hierarchy_entries => [ :name, { :scientific_synonyms => :name }, { :common_names => [ :name, :language ] } ] },
          :select => { :taxon_concepts => :id, :names => :string, :languages => :iso_639_1 })
        taxon_concepts.each do |tc|
          all_names = []
          all_synonyms = []
          all_common_names = {}
          tc.hierarchy_entries.each do |he|
            name = SolrAPI.text_filter(he.name.string)
            all_names << name if name && !all_names.include?(name)
            
            he.scientific_synonyms.each do |s|
              name = SolrAPI.text_filter(s.name.string)
              all_synonyms << name if name && !all_synonyms.include?(name)
            end
            
            he.common_names.each do |cn|
              name = SolrAPI.text_filter(cn.name.string)
              if name && (all_common_names[cn.language.iso_639_1].blank? || !all_common_names[cn.language.iso_639_1].include?(name))
                all_common_names[cn.language.iso_639_1] ||= []
                all_common_names[cn.language.iso_639_1] << name 
              end
            end
          end
          
          unless all_names.blank?
            @objects_to_send << { :keyword_type => 'scientific name',
                                  :keyword => all_names,
                                  :language => 'scientific',
                                  :resource_type => 'TaxonConcept',
                                  :resource_id => tc.id }
          end
          unless all_synonyms.blank?
            @objects_to_send << { :keyword_type => 'synonym',
                                  :keyword => all_synonyms,
                                  :language => 'scientific',
                                  :resource_type => 'TaxonConcept',
                                  :resource_id => tc.id }
          end
          unless all_common_names.blank?
            all_common_names.each do |language, names|
              @objects_to_send << { :keyword_type => 'common name',
                                    :keyword => names,
                                    :language => language,
                                    :resource_type => 'TaxonConcept',
                                    :resource_id => tc.id }
            end
          end
        end
      end
    end
  end
end
