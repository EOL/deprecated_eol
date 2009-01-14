class CreateContactSubjects < ActiveRecord::Migration
  def self.up
    create_table :contact_subjects do |t|
      t.string :title
      t.string :recipients
      t.boolean :active, :default=>true, :null=>false
      t.timestamps 
    end
  
    # Default subjects
    # Multiple recipients may be entered in a comma delimited list
    ContactSubject.create!(:title => 'Media Contact (interviews, image requests)', :recipients => "ByrnesB@si.edu")    
    ContactSubject.create!(:title => 'Request to curate a page', :recipients => "affiliate@example.com")
    ContactSubject.create!(:title => 'Request to upload images', :recipients => "affiliate@example.com")
    ContactSubject.create!(:title => 'Make a correction (images, spelling & grammar, information)', :recipients => "content-comments@example.com")    
    ContactSubject.create!(:title => 'Give feedback', :recipients => "content-comments@example.com")
    ContactSubject.create!(:title => 'Make a financial contribution', :recipients => "ByrnesB@si.edu")
    ContactSubject.create!(:title => 'Technical problems (difficulties with the website, search tool or user accounts)', :recipients => "support@example.com")    
    ContactSubject.create!(:title => 'Other (ideas for the website, things you would like to see)', :recipients => "support@example.com")      

  end

  def self.down
    drop_table :contact_subjects
  end
end
