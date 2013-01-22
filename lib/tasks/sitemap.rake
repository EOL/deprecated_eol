namespace :sitemap do

  desc 'Create sitemap with XML files'
  task :build_xml => :environment do
    sm = EOL::Sitemap.new()
    sm.build(:xml => true)
  end

  desc 'Destroy all sitemap files'
  task :destroy => :environment do
    EOL::Sitemap.destroy_all_sitemap_files
  end

  desc 'Create an image sitemap with XML files'
  task :build_images_xml => :environment do
    sm = EOL::ImageSitemap.new()
    sm.build(:xml => true)
  end

  desc 'Destroy all image sitemap files'
  task :destroy_images => :environment do
    EOL::ImageSitemap.destroy_all_sitemap_files
  end

end
