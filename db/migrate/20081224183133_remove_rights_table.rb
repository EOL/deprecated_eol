class RemoveRightsTable < ActiveRecord::Migration
  def self.up
    drop_table :rights
    drop_table :rights_roles
  end

  def self.down
    create_table :rights do |t|
       t.column :title, :string
       t.column :controller, :string
       t.timestamps
     end
     create_table(:rights_roles, :id=>false) do |t|
       t.references :right, :role
     end
     execute 'ALTER IGNORE TABLE `rights_roles` ADD PRIMARY KEY `key_id_for_rights_and_roles` (`right_id`, `role_id`)'

     Right.create(:title=>'Administrator',:controller=>'admin')
     Right.create(:title=>'Contact Us Administrator',:controller=>'contact')
     Right.create(:title=>'Contact Us Subject Administrator',:controller=>'contact_subject')
     Right.create(:title=>'CMS Administrator',:controller=>'content_page')
     Right.create(:title=>'Content Partner Administrator',:controller=>'content_partner_report')
     Right.create(:title=>'Error Log Administrator',:controller=>'error_log')
     Right.create(:title=>'Data Usage Reports Administrator',:controller=>'reports')    
     Right.create(:title=>'Web User Administrator',:controller=>'user')    
     Right.create(:title=>'Search Suggestion Administrator',:controller=>'search_suggestion')    


     Role.find_by_title('Administrator').rights << Right.find_by_title('Administrator')
     Role.find_by_title('Administrator - Contact Us Submissions').rights << Right.find_by_title('Contact Us Administrator')
     Role.find_by_title('Administrator - Site CMS').rights << Right.find_by_title('CMS Administrator')
     Role.find_by_title('Administrator - Site CMS').rights << Right.find_by_title('Contact Us Subject Administrator')
     Role.find_by_title('Administrator - Site CMS').rights << Right.find_by_title('Search Suggestion Administrator')
     Role.find_by_title('Administrator - Content Partners').rights << Right.find_by_title('Content Partner Administrator')
     Role.find_by_title('Administrator - Error Logs').rights << Right.find_by_title('Error Log Administrator')
     Role.find_by_title('Administrator - Usage Reports').rights << Right.find_by_title('Data Usage Reports Administrator')    
     Role.find_by_title('Administrator - Web Users').rights << Right.find_by_title('Web User Administrator')
  end
end
