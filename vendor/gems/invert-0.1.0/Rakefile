require "rake/rdoctask"

GEM_NAME = "invert"

begin
  require "jeweler"
  Jeweler::Tasks.new do |gem|
    gem.name = GEM_NAME
    gem.summary = "Inverse Comparison Wrapper"
    gem.description = gem.summary
    gem.email = "alex.r@askit.org"
    gem.homepage = "http://github.com/dadooda/invert"
    gem.authors = ["Glenn McDonald", "Alex Fortuna"]
    gem.files = FileList[
      "[A-Z]*.*",
      "*.gemspec",
      "generators/**/*",
      "lib/**/*.rb",
      "init.rb",
    ]
  end
rescue LoadError
  STDERR.puts "This gem requires Jeweler to be built"
end

desc "Rebuild gemspec and package"
task :rebuild => [:gemspec, :build]

desc "Push (publish) gem to RubyGems (aka Gemcutter)"
task :push => :rebuild do
  # Yet found no way to ask Jeweler forge a complete version string for us.
  vh = YAML.load(File.read("VERSION.yml"))
  version = [vh[:major], vh[:minor], vh[:patch]].join(".")
  pkgfile = File.join("pkg", [GEM_NAME, "-", version, ".gem"].to_s)
  system("gem", "push", pkgfile)
end

desc "Compile README preview"
task :readme do
  require "kramdown"

  doc = Kramdown::Document.new(File.read "README.md")

  fn = "README.html"
  puts "Writing '#{fn}'..."
  File.open(fn, "w") do |f|
    f.write(File.read "dev/head.html")
    f.write(doc.to_html)
  end
  puts ": ok"
end
