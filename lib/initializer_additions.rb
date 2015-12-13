module InitializerAdditions
  def self.add(name)
    file = File.join(File.dirname(__FILE__), "../config/#{name}.rb")
    if File.exists?(file)
      begin
        require file
      rescue LoadError
        puts "WARNING: COULD NOT LOAD #{file} **"
      end
    else
      puts "No config for #{name} found, skipping."
    end
  end
end
