namespace :views do
  desc 'Renames all your rhtml views to erb'
  task :rename do
    Dir.glob('app/views/**/*.rhtml').each do |file|
      puts `svn mv #{file} #{file.gsub(/\.rhtml$/, '.html.erb')}`
    end
  end
end

namespace :tmp do
  namespace :assets do 
    desc "Clears javascripts/cache and stylesheets/cache"
    task :clear => :environment do      
      FileUtils.rm(Dir['public/javascripts/cache/[^.]*'])
      FileUtils.rm(Dir['public/stylesheets/cache/[^.]*'])
    end
  end
end