desc 'Add simlinks to eol site-specific files which are not needed for open source release'
site_dir = Rails.root.join('vendor', 'eol_org').to_s
namespace :eol do
  desc 'checks out site-specific repository under vendor directory, change config dir with CONFIG_DIR environment var'
  task :checkout_repository do
    config_dir = ENV["CONFIG_DIR"] || 'rails3_config'
    puts "Checking out files from repository..."
    if FileTest.exists? site_dir
      if FileTest.exists? "#{site_dir}/.git"
        puts ".. Looks like you already have a repository, here."
        status = `cd #{site_dir}; git status 2> /dev/null`
        if status =~ /working directory clean/
          puts ".. Working directory clean."
          puts ".. Removing existing links (before update, so deleted files won't have links):"
          puts ".. Using #{config_dir} config directory."
          Dir.glob(site_dir + "/#{config_dir}/**/*").each do |file|
            if FileTest::file? file
              file_name = file.gsub("#{site_dir}/#{config_dir}/", 'config/')
              file_link = Rails.root.join(file_name)
              if FileTest.exists?(file_link)
                puts "   #{file_name}"
                FileUtils::rm file_link
              end
            end
          end
          puts ".. Updating:"
          sh "cd #{site_dir}; git pull"
        else
          raise "** ERROR: you have made changes to #{site_dir} and I don't want to overwrite them."
        end
      else
        puts ".. Looks like you have an older svn copy of the repository. Updating to git:"
        raise "** ERROR: You must specify a 'repo' parameter to complete this step." unless ENV['repo']
        FileUtils::rm_rf site_dir
        sh "git clone #{ENV['repo']} '#{site_dir}'"
      end
    else
      puts ".. Creating new git clone:"
      raise "** ERROR: You must specify a 'repo' parameter to complete this step." unless ENV['repo']
      sh "git clone #{ENV['repo']} '#{site_dir}'"
    end
  end

  desc 'creates soft links to site-specific files'
  task :site_specific => :checkout_repository do
    puts "++ Adding links to site-specific files..."
    puts ".. Using #{config_dir} config directory."
    Dir.glob(site_dir + "/#{config_dir}/**/*").each do |file|
      if FileTest::file? file
        file_name = file.gsub("#{site_dir}/#{config_dir}/", 'config/')
        file_link = Rails.root.join(file_name)
        dir =  File.dirname file_link
        FileUtils::mkdir_p(dir) unless FileTest.exists?(dir)
        FileUtils::rm file_link if FileTest.exists?(file_link)
        begin
          FileUtils::ln_s file, file_link
        rescue => e
          puts "** WARING:"
          puts e.message
        end
        puts "   #{file_name}"
      end
    end
  end

  desc 'removes links to site-speific files and deletes their repository from vendor'
  task :clean_site_specific do
    puts "++ Cleaning up site-specific files..."
    if FileTest.exists? site_dir
      puts ".. Using #{config_dir} config directory."
      Dir.glob(site_dir + "/#{config_dir}/**/*").each do |file|
        if FileTest::file? file
          file_link = Rails.root.join(file.gsub("#{site_dir}/#{config_dir}/", 'config/'))
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
