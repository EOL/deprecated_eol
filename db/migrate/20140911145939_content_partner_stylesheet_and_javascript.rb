class ContentPartnerStylesheetAndJavascript < ActiveRecord::Migration
  def up
    add_column :content_partners, :stylesheet, :string
    add_column :content_partners, :javascript, :string
    execute "UPDATE content_partners SET stylesheet='wikipedia', javascript='wiki_ogg_player' 
      WHERE full_name='Wikipedia'"
  end

  def down
    remove_column :content_partners, :stylesheet
    remove_column :content_partners, :javascript
  end
end
