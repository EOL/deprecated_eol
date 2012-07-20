class CreateSortStyleReverseSortOrder < ActiveRecord::Migration
  def self.up
    reverse_sort_field = SortStyle.create()
    TranslatedSortStyle.create(:sort_style => reverse_sort_field, :name => 'Reverse Sort Field',
      :language => Language.english_for_migrations)
  end

  def self.down
    reverse_sort_field = SortStyle.find_by_translated(:name, 'Reverse Sort Field', 'en')
    reverse_sort_field.translations.each{ |tr| tr.destroy }
    reverse_sort_field.destroy
  end
end
