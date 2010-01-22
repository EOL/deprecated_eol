desc 'Add simlinks to eol site-specific files which are not needed for open source release'
site_dir = "#{RAILS_ROOT}/vendor/eol_org"
namespace :eol do
  desc 'checks out site-specific repository under vendor directory'
  task :checkout_repository do
    if ENV['repo']
      puts "Checking out files from repository..."
      FileUtils::rm_rf site_dir if FileTest.exists? site_dir
      sh "svn co #{ENV['repo']} '#{site_dir}'"
    else
      puts <<HELP_MSG

Usage: 

#to create site-specific files:
rake eol:site_specific repo=uri_to_repository

#to clean up
rake eol:clean_site_specific


HELP_MSG
      exit
    end
  end
  
  desc 'creates soft links to site-specific files'
  task :site_specific => :checkout_repository do
    puts "Adding links to site-specific files..."
    Dir.glob(site_dir + "/**/*").each do |file|
      if FileTest::file? file
        file_link = RAILS_ROOT + file.gsub(site_dir,'')
        dir =  File.dirname file_link
        FileUtils::mkdir_p(dir) unless FileTest.exists?(dir)
        FileUtils::rm file_link if FileTest.exists?(file_link)
        FileUtils::ln_s file, file_link
        puts ' ' * 5  + file_link
      end
    end
  end

  desc 'removes links to site-speific files and deletes their repository from vendor'
  task :clean_site_specific do
    puts "Cleaning up site-specific files..."
    if FileTest.exists? site_dir
      Dir.glob(site_dir + "/**/*").each do |file|
        if FileTest::file? file
          file_link = RAILS_ROOT + file.gsub(site_dir,'')
          begin
            FileUtils::rm file_link 
          rescue SystemCallError
            puts 'WARNING: Could not find file ' + file
          end
        end
      end
      FileUtils::rm_rf site_dir
    else
      puts <<MSG

Site specific repository does not exist, cannot clean up.

MSG
    end
  end
end
