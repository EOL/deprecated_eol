class TraitBank
  class ResourcePorter
    def self.port(resource)
      porter = self.new
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
      if @triples.empty?
        EOL.log("No data to insert, skipping.", prefix: ".")
      else
        unless insert_triples
          EOL.log("Data not inserted: #{@triples.inspect}", prefix: "!")
          raise "Failed to insert data"
        end
      end
      EOL.log_return
      @taxa
    end

    def build_traits
      TraitBank.paginate(TraitBank.measurements_query(@resource)) do |results|
        results.each do |row|
          raise "No value for #{row[:trait]}!" unless row[:value]
          @taxa << row[:page].to_s.sub(TraitBank.taxon_re, "\\1")
          @triples << "<#{row[:page]}> a eol:page ; "\
            "<#{row[:predicate]}> <#{row[:trait]}>"
          @triples << "<#{row[:trait]}> a eol:trait"
          add_meta(row, "http://rs.tdwg.org/dwc/terms/measurementValue", :value)
          add_meta(row, "http://rs.tdwg.org/dwc/terms/measurementUnit", :units)
          add_meta(row, "http://rs.tdwg.org/dwc/terms/sex", :sex)
          add_meta(row, "http://rs.tdwg.org/dwc/terms/lifeStage", :life_stage)
          add_meta(row, "http://eol.org/schema/terms/statisticalMethod",
            :statistical_method)
          @triples << "<#{row[:trait]}> dc:source <#{@resource.graph_name}>"
          @traits << row[:trait]
        end
      end
    end

    def build_associations
      TraitBank.paginate(associations_query(@resource)) do |results|
        results.each do |row|
          @triples << "<#{row[:page]}> a eol:page ;"\
            "<#{row[:predicate]}> <#{row[:target_page]}> ;"\
            "dc:source <#{@resource.graph_name}>"
          @triples << "<#{row[:target_page]}> a eol:page ;"\
            "<#{row[:inverse]}> <#{row[:page]}> ;"\
            "dc:source <#{@resource.graph_name}>"
          @traits << row[:trait]
        end
      end
    end

    def build_metadata
      EOL.log("Finding metadata for #{@traits.count} traits...", prefix: ".")
      @traits.each_with_index do |trait, index|
        EOL.log("index #{index}", prefix: ".") if index % 1_000 == 0
        begin
          TraitBank.connection.query(metadata_query(@resource, trait)).
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
                "<http://rs.tdwg.org/dwc/terms/measurementValue> #{val} ;"\
                "<http://rs.tdwg.org/dwc/terms/measurementUnit> #{units}"
            end
          end
        # This was causing a lot of trouble when I was attempting it:  :(
        rescue => e
          EOL.log("ERROR: #{e.message}")
          raise e
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
