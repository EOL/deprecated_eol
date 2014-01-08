class Location

  # tableless model
  include ActiveModel::Validations
  include ActiveModel::Translation
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  LATLNG_REGEX = /^[ ]*?([-+]?\d{1,2}(?:[.]\d*)?)[, ]+([-+]?\d{1,3}(?:[.]\d*)?)[ .]*?$/

  attr_accessor :location, :latitude, :longitude

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

end
