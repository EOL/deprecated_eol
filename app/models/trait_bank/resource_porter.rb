class TraitBank
  class ResourcePorter
    def self.port(resource)
      porter = self.new(resource)
      porter.port
    end

    def initialize(resource)
      @resource = resource
      reset
    end

    def reset
      @triples = []
      @taxa = Set.new
      @traits = Set.new
    end

    # Returns the set of taxa which were affected. NOTE that you should probably
    # flatten those taxa in TB.
    def port
      EOL.log_call
      reset
      # TODO: Ideally, we would first get a diff of what's in the graph vs what
      # we're going to put in the graph, and add the new stuff and remove the
      # old. That's a lot of work! Not doing that now.
      TraitBank.delete_resource(@resource)
      build_traits
      build_associations
      build_metadata
      build_references
      if @triples.empty?
        EOL.log("No data to insert, skipping.", prefix: ".")
      else
        unless insert_triples
          EOL.log("Data not inserted: #{@triples.inspect}", prefix: "!")
          raise "Failed to insert data"
        end
      end
      EOL.log_return
      # Clear caches!
      @taxa.each do |id|
        Rails.cache.delete(PageTraits.cache_key(id))
      end
      @taxa
    end

    def build_traits
      TraitBank.paginate(TraitBank.measurements_query(@resource)) do |results|
        results.each do |row|
          raise "No value for #{row[:trait]}!" unless row[:value]
          @taxa << row[:page].to_s.sub(TraitBank.taxon_re, "\\2")
          @triples << "<#{row[:page]}> a eol:page ; "\
            "<#{row[:predicate]}> <#{row[:trait]}>"
          @triples << "<#{row[:trait]}> a eol:trait ; "\
            "eolterms:resource <#{@resource.graph_name}>"
          add_meta(row, TraitBank.value_uri, :value)
          add_meta(row, TraitBank.unit_uri, :units)
          add_meta(row, TraitBank.sex_uri, :sex)
          add_meta(row, TraitBank.life_stage_uri, :life_stage)
          add_meta(row, TraitBank.statistical_method_uri, :statistical_method)
          @traits << row[:trait]
        end
      end
    end

    def build_associations
      TraitBank.paginate(TraitBank.associations_query(@resource)) do |results|
        results.each do |row|
          # This is a sloppy way to ensure inverse relationships aren't added
          # twice, because inverse relationships are both stored in the traits
          # AND read using owl:inverseOf. ...That is not useful (because they
          # use the same measurement ID but have different values, the porter
          # stores them both under the same ID and thus you get things like X
          # eats Y, Y eaten by X, Y eats X, Y eatenBy X, which is clearly bad)!
          # It would be *better* if we parsed the old triples to ensure we have
          # the correct interpretation... but that's probably only going to fix
          # very weird cases and it would take a lot longer, so likely not
          # actually worth it.
          next if @traits.include?(row[:trait])
          @triples << "<#{row[:page]}> a eol:page ; "\
            "<#{row[:predicate]}> <#{row[:trait]}>"
          @triples << "<#{row[:trait]}> a eol:trait ; "\
            "eolterms:resource <#{@resource.graph_name}> ; "\
            "eol:associationType <#{row[:predicate]}> ; "\
            "eol:objectPage <#{row[:target_page]}> ; "\
            "eol:subjectPage <#{row[:page]}>"
          unless row[:inverse].blank?
            # @triples << "<#{row[:target_page]}> a eol:page ;"\
            #   "<#{row[:inverse]}> <#{row[:trait]}>"
            @triples << "<#{row[:trait]}> eol:inverseAssociationType <#{row[:inverse]}>"
          end
          @traits << row[:trait]
          @taxa << row[:page].to_s.sub(TraitBank.taxon_re, "\\2")
          @taxa << row[:target_page].to_s.sub(TraitBank.taxon_re, "\\2")
        end
      end
    end

    def build_metadata
      EOL.log("Finding metadata for #{@traits.count} traits...", prefix: ".")
      @traits.each_with_index do |trait, index|
        EOL.log("index #{index}", prefix: ".") if index % 1_000 == 0
        begin
          TraitBank.metadata_in_bulk(@resource, trait).
            each do |h|
            # ?trait ?predicate ?meta_trait ?value ?units
            if h[:units].blank?
              add_meta(h, h[:predicate], :value)
            else
              @triples << "<#{h[:trait]}> <#{h[:predicate]}> <#{h[:meta_trait]}>"
              val = TraitBank.uri?(h[:value]) ?
                "<#{h[:value]}>" :
                TraitBank.quote_literal(h[:value])
              units = TraitBank.uri?(h[:units]) ?
                "<#{h[:units]}>" :
                # TODO: THIS SHOULD NOT HAPPEN. tell someone?
                TraitBank.quote_literal(h[:units])
              @triples << "<#{h[:meta_trait]}> a eol:trait ;"\
                "<#{TraitBank.value_uri}> #{val} ;"\
                "<#{TraitBank.unit_uri}> #{units}"
            end
          end
        # This was causing a lot of trouble when I was attempting it:  :(
        rescue => e
          EOL.log("ERROR: #{e.message}")
          raise e
        end
      end
    end

    def build_references
      TraitBank.paginate(TraitBank.references_query(@resource)) do |results|
        results.each do |row|
          @triples << "<#{row[:trait]}> <#{TraitBank.full_reference_uri}> "\
            "#{TraitBank.quote_literal(row[:full_reference])}"
        end
      end
    end

    def add_meta(row_hash, uri, key, options = {})
      return if row_hash[key].nil?
      triple = "<#{row_hash[:trait]}> <#{uri}> "
      if options[:literal] || ! TraitBank.uri?(row_hash[key])
        triple << TraitBank.quote_literal(row_hash[key])
      else
        triple << "<#{row_hash[key]}>"
      end
      @triples << triple
    end

    def insert_triples
      TraitBank.connection.insert_data(data: @triples,
        graph_name: TraitBank.graph)
    end
  end
end
