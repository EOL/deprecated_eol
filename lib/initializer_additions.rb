module InitializerAdditions
  def self.add(name)
    file = File.join(File.dirname(__FILE__), "../config/#{name}.rb")
    if File.exists?(file)
      begin
        require file
      rescue LoadError
        EOL.log("WARNING: COULD NOT LOAD #{file} **", prefix: "*")
      end
    else
      EOL.log("No config for #{name} found, skipping.", prefix: "+")
    end
  end
end
