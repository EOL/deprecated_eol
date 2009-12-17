require 'net/http'
require 'uri'
require 'json'

class SolrAPI
  attr_reader  :server_url

  def initialize(server_url = nil)
    server_url ||= $SOLR_SERVER
    @server_url = URI.parse(server_url)
  end

  def delete_all_documents
    data = '<delete><query>*:*</query></delete>' 
    post('update', data)
    commit
  end

  def get_results(query)
    res = get(query)
    res = JSON.load res.body
    res['response']
  end

  def commit
    post('update', '<commit />')
  end

  # See the solr_api library spec for some examples.
  def create(ruby_data)
    solr_xml = build_solr_xml('add', ruby_data)
    post('update', solr_xml)
    commit
  end

  def query
  end
  
  # Takes an array of hashes. Each hash has only string or array of strings values. Array is converted into an xml ready
  # for either create or update methods of Solr API
  #
  # See the solr_api library spec for some examples.
  def build_solr_xml(command, ruby_data)
    builder = Nokogiri::XML::Builder.new do |sxml|
      sxml.send(command) do 
        ruby_data = [ruby_data] if ruby_data.class != Array
        ruby_data.each do |data|
          sxml.doc_ do
            data.keys.each do |key|
              data[key] = [data[key]] if data[key].class != Array
              data[key].each do |val|
                sxml.field(val, :name => key.to_s) 
              end
            end
          end
        end
      end
    end
    builder.to_xml
  end  

  # This method creates indexes based on the *actual* TaxonConcept instances passed in as an argument (enumerable).
  def build_indexes(taxon_concepts = nil)
    taxon_concepts ||= TaxonConcept.all
    data = []
    taxon_concepts.each do |taxon_concept|
      images = taxon_concept.images
      data << {:common_name => taxon_concept.all_common_names.map {|n| n.string },
               :preferred_scientific_name => [taxon_concept.scientific_name],
               :scientific_name => taxon_concept.all_scientific_names.map {|n| n.string },
               :taxon_concept_id => [taxon_concept.id],
               :vetted_id => taxon_concept.vetted_id,
               :published => taxon_concept.published,
               :supercedure_id => taxon_concept.supercedure_id,
               :top_image_id => images.blank? ? '' : taxon_concept.images.first.id }
    end
    create(data)
  end

  private

  def post(method, data) 
    request = Net::HTTP::Post.new(@server_url.path + "/#{method}")
    request.body = data
    request.content_type = 'application/xml'
    response = Net::HTTP.start(@server_url.host, @server_url.port) {|http| http.request(request) }
  end

  def get(query)
    response = Net::HTTP.start(@server_url.host, @server_url.port) {|http| http.get(@server_url.path + "/select/?q=*:*&version=2.2&start=0&rows=10&indent=on&wt=json") }
    response
  end

end
