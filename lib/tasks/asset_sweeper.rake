# Author Anil
# Task to remove unused images
namespace :asset_sweeper do
  task :remove_unused_images => :environment do
    require "fileutils"
    img=Dir.glob("**/app/assets/images/**/*.jpg")+Dir.glob("**/app/assets/images/**/*.png")+Dir.glob("**/app/assets/images/**/*.gif")
    data=Dir.glob("**/*.htm*")+Dir.glob("**/*.css")+Dir.glob("**/*.js")+Dir.glob("**/*.rb")+Dir.glob("**/*.sass")+Dir.glob("**/*.haml")+Dir.glob("**/*.erb")+Dir.glob("**/*.htc")+Dir.glob("**/*.scss")
    puts img.length.to_s+" images found & "+data.length.to_s+" files found to search against"
    content=""
    data.each do |f|
      content+=File.open(f, 'r').read
    end
    img.each do |m|
      if not content=~ Regexp.new("\\b"+File.basename(m)+"\\b")
        FileUtils.mkdir_p "unused/"+File.dirname(m)
        FileUtils.mv m,"unused/"+m
        puts "Image "+m+" moved to unused/"+File.dirname(m)+" folder"
      end
    end
  end

  task :list_unused_stylesheets => :environment do
    stylesheets = Dir.glob("**/*.css")
    data=Dir.glob("**/*.htm*")
    content=""
    data.each do |f|
      content+=File.open(f, 'r').read
    end
    p"=========================================================="
    p'Following stylesheets are not called from any view in application. Hence look like unused ones. Please verity and delete if they are not being used actually.'
    stylesheets.each do |s|
      if not content=~ Regexp.new("\\b"+File.basename(s)+"\\b")
        p"#{s}"
      end
    end
    p"=========================================================="
  end

  task :list_unused_javascripts => :environment do
    javascripts = Dir.glob("**/*.js")
    data=Dir.glob("**/*.htm*")
    content=""
    data.each do |f|
      content+=File.open(f, 'r').read
    end
    p"=========================================================="
    p'Following javascripts are not called from any view in application. Hence look like unused ones. Please verity and delete if they are not being used actually.'
    javascripts.each do |j|
      if not content=~ Regexp.new("\\b"+File.basename(j)+"\\b")
        p"#{j}"
      end
    end
    p"=========================================================="
  end

  task :find_missing_images => :environment do
    image_paths = []
    data = Dir.glob("**/*.css")
    content=""
    data.each do |f|
      content+=File.open(f, 'r').read
    end
    next_image_path = true
    while next_image_path
      arr = content.split('url(')
      arr.delete_at(0)
      content = arr.join('url(')
      if arr.size > 1
        arr = content.split(')')
        image_paths << arr[0]
        arr.delete_at(0)
        content = arr.join(')')
      else
        next_image_path = false
      end
    end
    image_paths.each do |path|
      path = path.gsub('../','').gsub("'","").gsub('"','').gsub('./','').gsub('//','')
      path = path.starts_with?('/') ? 'public'+path : 'public/'+path
      unless File.exist?(path)
        p"image is missing at #{path}"
      end
    end
  end
end
