# sets up a basic foundation - enough data to run the application

Language.gen      :iso_639_1 => 'en'

ContentPage.gen   :page_name => 'Home', :language_abbr => 'en'

# Required Roles
Role.gen          :title => 'Curator'
Role.gen          :title => 'Moderator'
Role.gen          :title => 'Administrator'
