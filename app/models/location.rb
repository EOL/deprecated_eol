class Location

  # tableless model
  include ActiveModel::Validations
  include ActiveModel::Translation
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  LATLNG_REGEX = /^[ ]*?([-+]?\d{1,2}(?:[.]\d*)?)[, ]+([-+]?\d{1,3}(?:[.]\d*)?)[ .]*?$/

  attr_accessor :location, :latitude, :longitude, :language_id
                :index, :result, :taxon_groups
  attr_reader   :errors
  attr_writer   :taxon_concepts

  validates :latitude, numericality: true
  validates :longitude, numericality: true

  # TODO geocoded_by :location
  # TODO reverse_geocoded_by :latitude, :longitude

  def initialize(attributes = {})
    @errors         = ActiveModel::Errors.new(self)
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

  def taxon_concepts
    @taxon_concepts ||= find_taxon_concepts
  end

  def find_taxon_concepts
    @result = EOL::LivesHere.search(latitude, longitude, { radius: 50000 })
    if @result.valid?
      @taxon_groups = @result.taxon_groups
      @taxon_concepts = TaxonConcept.where(id: @result.taxon_concept_ids)
      TaxonConcept.preload_for_shared_summary(@taxon_concepts, {language_id: language_id})
    else
      errors.add(
        :result,
        I18n.t('activerecord.errors.models.location.attributes.result.invalid')
      )
    end
  end

  def find_taxon_concept_by_id(id)
    return nil if taxon_concepts.nil?
    taxon_concepts.select{|tc| tc.id == id.to_i}.first
  end

  def geocode
    # TODO convert string location to lat long
  end

  def reverse_geocode
    # TODO convert lat long to string location
  end

end
