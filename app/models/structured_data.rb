class StructuredData

  attr_accessor :graph_name
  attr_reader :subject, :predicate, :object, :graph_name, :entry_to_taxon_graph_name, :uri, :taxon_uri,
    :target_taxon_uri, :metadata

  def initialize(opts={})
    options = opts.dup # Makes it clearer when we delete things...
    raise 'Subject must be a TaxonConcept' unless options[:subject].is_a?(TaxonConcept)
    if options[:graph_name].blank?
      raise 'Resource must be an instance of class Resource' unless options[:resource].is_a?(Resource)
    end
    # NOTE - you must delete options as you parse them; all other options are treated as metadata.
    @subject = options.delete(:subject)
    @predicate = options.delete(:predicate)
    @object = options.delete(:object)
    @resource = options.delete(:resource)
    @taxon_name = options.delete(:taxon_name)
    @graph_name = options.delete(:graph_name) || "#{Rails.configuration.uri_resources_prefix}#{@resource.id}"
    @entry_to_taxon_graph_name = "#{@graph_name}/mappings"
    @unique_id = Digest::MD5.hexdigest(self.inspect)
    @taxon_uri = taxon_uri_for(@subject)
    @occurrence_uri = occurrence_uri_for(@subject)
    @metadata = {}
    # You may pass in an array of UserAddedDataMetadata instances as "metadata:"
    user_added_metadata = options.delete(:metadata) || []
    user_added_metadata.each do |meta|
      @metadata[meta.predicate] = meta.object
    end
    # Or you may add metadata as raw options:
    options.each do |a, v|
      if EOL::Sparql.is_uri?(a)
        @metadata[a] = v
      end
    end
  end

  def update_triplestore
    remove_from_triplestore
    add_to_triplestore
  end

  def remove_from_triplestore
    sparql.delete_uri(graph_name: @graph_name, uri: @uri)
    sparql.delete_uri(graph_name: @entry_to_taxon_graph_name, uri: @taxon_uri)
    sparql.delete_uri(graph_name: @graph_name, uri: @occurrence_uri)
    sparql.delete_uri(graph_name: @entry_to_taxon_graph_name, uri: @target_taxon_uri) if @target_taxon_uri
    if @target_occurrence_uri
      sparql.delete_uri(graph_name: @graph_name, uri: @target_occurrence_uri)
      sparql.delete_uri(graph_name: @entry_to_taxon_graph_name, uri: @target_occurrence_uri)
    end
  end

  def add_to_triplestore
    sparql.insert_data(data: [ turtle ], graph_name: @graph_name)
    sparql.insert_data(data: [ mappings_turtle ], graph_name: @entry_to_taxon_graph_name)
  end

  def turtle
    raise 'this method is not implemented'
  end

  def mappings_turtle
    str = "<#{@taxon_uri}> dwc:taxonConceptID <" + UserAddedData::SUBJECT_PREFIX + @subject.id.to_s + ">"
    if @target_taxon_uri
      str += ". <#{@target_taxon_uri}> dwc:taxonConceptID <" + UserAddedData::SUBJECT_PREFIX + @object.id.to_s + ">"
    end
    return str
  end

  def sparql
    @sparql ||= EOL::Sparql.connection
  end

  def taxon_uri_for(taxon_concept)
    @graph_name + "/taxa/" + Digest::MD5.hexdigest(taxon_concept.inspect)
  end

  def occurrence_uri_for(taxon_concept)
    @graph_name + "/occurrences/" + Digest::MD5.hexdigest(taxon_concept.inspect)
  end

end
