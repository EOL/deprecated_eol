class ViewStyle < ActiveRecord::Base
  uses_translations
  has_many :collections

  def self.create_defaults
    TranslatedViewStyle.reset_cached_instances
    ViewStyle.reset_cached_instances
    ['List', 'Gallery', 'Annotated'].each do |name|
      unless TranslatedViewStyle.exists?(:language_id => Language.english.id, :name => name)
        vstyle = ViewStyle.create
        TranslatedViewStyle.create(:name => name, :view_style_id => vstyle.id, :language_id => Language.english.id)
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
