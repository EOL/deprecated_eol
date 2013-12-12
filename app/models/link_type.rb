class LinkType < ActiveRecord::Base

  uses_translations
  has_many :data_objects_link_type
  has_many :data_objects, through: :data_objects_link_type

  include Enumerated
  enumerated :label, ['Blog', 'News', 'Organization', 'Paper', 'Multimedia', 'Citizen Science']

  def to_s
    label
  end

end
