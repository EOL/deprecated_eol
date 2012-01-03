namespace :sitemap do
  
  desc 'Create sitemap with text files'
  task :build => :environment do
    sm = EOL::Sitemap.new()
    sm.build
  end
  
  desc 'Create sitemap with XML files'
  task :build_xml => :environment do
    sm = EOL::Sitemap.new()
    sm.build(:xml => true)
  end
  
  desc 'Destroy all sitemap files'
  task :destroy => :environment do
    EOL::Sitemap.destroy_all_sitemap_files
  end
end
