# sets up a basic foundation - enough data to run the application

# required enumeration values
Factory(:language, :iso_639_1 => 'en' )

# / Home page
Factory(:content_page, :page_name => 'Home', :language_abbr => 'en')
