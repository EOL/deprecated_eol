class Location

  # tableless model
  include ActiveModel::Validations
  include ActiveModel::Translation
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :location

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

end
