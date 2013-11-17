class ViewStyle < ActiveRecord::Base
  uses_translations
  has_many :collections

  include Enumerated
  enumerated :name, %w(List Gallery Annotated)

  def self.create_defaults
    ['List', 'Gallery', 'Annotated'].each do |name|
      unless TranslatedViewStyle.exists?(:language_id => Language.default.id, :name => name)
        vstyle = ViewStyle.create
        TranslatedViewStyle.create(:name => name, :view_style_id => vstyle.id, :language_id => Language.default.id)
      end
    end
  end

end
