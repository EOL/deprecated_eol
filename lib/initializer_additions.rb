module InitializerAdditions
  def self.add(name)
    puts File.join(File.dirname(__FILE__), "../config/#{name}.rb")
    file = File.join(File.dirname(__FILE__), "../config/#{name}.rb")
    if File.exists?(file)
      begin
        require file
        puts "** LOADED: #{name} **"
      rescue LoadError
        puts "** WARNING: COULD NOT LOAD #{file} **"
      end
    else
      puts "++ No config for #{name} found, skipping."
    end
  end
end