class ViewStyle < ActiveRecord::Base
  uses_translations
  has_many :collections

  include EnumDefaults

  set_defaults :name,
    ['List', 'Gallery', 'Annotated']

end
