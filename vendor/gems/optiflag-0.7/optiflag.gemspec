require 'rake'
Gem::Specification.new do |spec|
	spec.name = "optiflag"
        spec.require_path = '.'	
	spec.version = "0.7"
	spec.summary = "OptiFlag is an embeddable DSL library for declaring and using command-line options/flags in any Ruby program."
	spec.author = "Daniel Eklund"
	spec.email = "doeklund@gmail.com"
	spec.homepage = "http://rubyforge.org/projects/optiflag/"
	spec.files = FileList['**/*'].to_a
	spec.test_files = FileList['testcases/tc*'].to_a - ["testcases/tc_flagall.rb"]
	spec.has_rdoc = true
	spec.rubyforge_project = 'optiflag'
end  
