class ViewStyle < ActiveRecord::Base

  uses_translations
  has_many :collections

  include Enumerated
  enumerated :name, %w(List Gallery Annotated)

end
