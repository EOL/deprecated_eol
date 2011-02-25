Dir[File.join(File.dirname(__FILE__), "lib/**/*.rb")].each do |fn|
  require fn
end
