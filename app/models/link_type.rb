class LinkType < ActiveRecord::Base
  uses_translations
  has_many :data_objects_link_type
  has_many :data_objects, :through => :data_objects_link_type

  include EnumDefaults

  set_defaults :label,
    ['Blog', 'News', 'Organization', 'Paper', 'Multimedia', 'Citizen Science'],
    translated: true

  def to_s
    label
  end

end
