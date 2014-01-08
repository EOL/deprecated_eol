require 'open-uri'
require 'json'

class Location

  # tableless model
  include ActiveModel::Validations
  include ActiveModel::Translation
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  LATLNG_REGEX = /^[ ]*?([-+]?\d{1,2}(?:[.]\d*)?)[, ]+([-+]?\d{1,3}(?:[.]\d*)?)[ .]*?$/

  attr_accessor :location, :latitude, :longitude, :taxon_concepts,
                :index, :response
  attr_reader   :errors

  def initialize(attributes = {})
    @errors         = ActiveModel::Errors.new(self)
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

  def load_taxa(options = nil)
    begin
      url = "#{LIVES_HERE_URL}?lat=#{latitude}&lon=#{longitude}&radius=50000"
      @response = JSON.load(open(url)).to_hash
      if response['success']
        ids = response['results'].collect do |g|
          g['species'].collect{|t| t['eol_page_id'].to_i}
        end.compact.flatten.uniq
        @taxon_concepts = TaxonConcept.where(id: ids)
        TaxonConcept.preload_for_shared_summary(@taxon_concepts, {})
        return
      end
    rescue OpenURI::HTTPError => e
      logger.error e.message
    end

    errors.add(
      :results,
      I18n.t('activerecord.errors.models.location.attributes.response.invalid')
    )
  end

  def find_taxon_concept_by_id(id)
    return nil if taxon_concepts.nil?
    taxon_concepts.select{|tc| tc.id == id.to_i}.first
  end

end
