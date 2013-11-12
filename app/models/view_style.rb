class ViewStyle < ActiveRecord::Base
  uses_translations
  has_many :collections

  def self.create_defaults
    ['List', 'Gallery', 'Annotated'].each do |name|
      unless TranslatedViewStyle.exists?(:language_id => Language.default.id, :name => name)
        vstyle = ViewStyle.create
        TranslatedViewStyle.create(:name => name, :view_style_id => vstyle.id, :language_id => Language.default.id)
      end
    end
  end

  def self.list
    cached_find_translated(:name, 'List')
  end

  def self.gallery
    cached_find_translated(:name, 'Gallery')
  end

  def self.annotated
    cached_find_translated(:name, 'Annotated')
  end

end
