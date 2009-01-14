class CreateContentPages < ActiveRecord::Migration
  def self.up
    
    require 'faker'

    create_table :content_pages, :force => true do |t|
      t.string :page_name, :default=>'', :null=>false
      t.string :title, :default=>'',:null=>false
      t.string :language_key, :default=>'', :null=>false
      t.integer :content_section_id
      t.integer :sort_order, :default=>1, :null=>false
      t.text :left_content, :null=>false # Note that these once had a default value of '', buy MySQL hated it.
      t.text :main_content, :null=>false # Note that these once had a default value of '', buy MySQL hated it.
      t.boolean :active, :default=>true, :null=>false
      t.timestamps
    end

    content_page = mm(ContentPage)

    # These are sections that don't have left content:
    {'About EOL'      => ['Who We Are', 'Donors', 'Institutional Partners','Milestones', 'Upcoming Events', 'Employment', 'Industry Partners'],
     'Using the Site' => ['Screencasts', 'FAQs'],
     'Press Room'     => ['Press Releases', 'Publications', 'Newsletter'],
     'Footer'         => ['Terms Of Use']}.each do |section, titles|
      sort_order = 0
      titles.each do |title|
        content_page.create!(:page_name => title, :title=>title, :left_content => '',
                            :content_section_id => ContentSection.find_by_name(section).id,
                            :main_content => "<h1>#{ Faker::Company.catch_phrase }</h1><p>#{ Faker::Lorem.paragraphs(3).join('</p><p>') }</p>",:sort_order=>sort_order += 1)
      end
    end   
    # The home page is special, and we want some "real-ish" content there:
    content_page.create!(:page_name => 'Home',
                        :title => 'Home', 
                        :left_content => '<h1>Welcome</h1>The Encyclopedia of Life (EOL) is an ambitious project to organize and make available via the Internet virtually all information about life present on Earth. At its heart lies a series of Web sites—one for each of the approximately 1.8 million known species.  Each site is constantly evolving and features dynamically synthesized content ranging from historical literature and biological descriptions to stunning images, videos and distribution maps. Join us as we explore the richness of Earth’s biodiversity!<br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br />',
                        :main_content => '<h1>What\'s New?</h1><ul class="helplist"><li>We recently welcomed new <a href="/content/page/data_partners">content partners</a> and added rich information on many new species. The EOL staff enjoys watching the updated home page sample the new ants, birds, mammals, fungi, plants, and spiders, and we hope you do too!</li><li>The Encyclopedia of Life and Microsoft Photosynth bring a new experience to users! <a href="/content/page/photosynth">Explore the innovative software</a> that provides a fresh way to visualize species.</li></ul><br /><br /><h1>Help Us</h1><p>EOL is an unprecedented global effort and we want you to be a part of it. Natural history museums, botanical gardens, other research institutions, and dedicated individuals are working to create the most complete biodiversity database on the Web, but without your help it cannot be done. Here are some ways in which you can become involved:</p><ul class="helplist"><li><strong>Provide content.</strong> (coming later in 2008)</li> <li><strong>Become a curator.</strong> (coming later in 2008, but you can <a href="/contact_us">contact us</a> now to express interest)</li><li><strong>Become a donor to the EOL.</strong> Make <a href="/donate">a financial donation</a>.</li></ul>',
                        :content_section_id => ContentSection.find_by_name('Home Page').id, 
                        :sort_order => 1)

  end

  def self.down
    drop_table :content_pages
  end
end
