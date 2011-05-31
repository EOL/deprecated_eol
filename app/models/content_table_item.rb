class ContentTableItem < ActiveRecord::Base
  belongs_to :content_table
  belongs_to :table_of_content
end
