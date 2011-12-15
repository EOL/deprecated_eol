class AddSortFieldToCollectionItems < ActiveRecord::Migration
  def self.up
    add_column :collection_items, :sort_field, :string
    sort_field_style = SortStyle.create
    TranslatedSortStyle.create(:language => Language.english_for_migrations, :name => 'Sort Value', :sort_style => sort_field_style)
  end

  def self.down
    remove_column :collection_items, :sort_field
    SortStyle.sort_field.translations.each{ |tr| tr.destroy }
    SortStyle.sort_field.destroy
  end
end
