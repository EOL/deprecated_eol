class TranslatedTocItem < ActiveRecord::Base
  self.table_name = 'translated_table_of_contents'
  belongs_to :toc_item, foreign_key: 'table_of_contents_id'
  belongs_to :language
end
