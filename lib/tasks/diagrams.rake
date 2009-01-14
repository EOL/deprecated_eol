# This suite of tasks generate graphical diagrams by introspecting the code base.
# A UNIX-like environment is required as well as binaries from the following system packages in your PATH...
# 
# * The railroad gem. (http://railroad.rubyforge.org)
# * The graphviz package which includes the `dot` and `neato` command-line utilities. MacPorts users can install in via `sudo port install graphviz`.
# * The `sed` command-line utility, which should already be available on all sane UNIX systems.
#
# Author: Preston Lee <preston.lee at openrain.com>


# Returns an absolute path for the following file.
def full_path(name = 'test.txt')
  f = File.join(RAILS_ROOT, 'doc', name)
  f.to_s
end
  
namespace :diagram do

  @MODELS_ALL_SVG = full_path('models_complete.svg').freeze
  @MODELS_BRIEF_SVG = full_path('models_brief.svg').freeze
  @CONTROLLERS_ALL_SVG = full_path('controllers_complete.svg').freeze
  @CONTROLLERS_BRIEF_SVG = full_path('controllers_brief.svg').freeze
 
  namespace :models do

    desc 'Generates an SVG class diagram for all models.'
    task :complete do
      f = @MODELS_ALL_SVG
      puts "Generating #{f}"
      sh "railroad -ilamM | dot -Tsvg > #{f}"
    end

    desc 'Generates an abbreviated SVG class diagram for all models.'
    task :brief do
      f = @MODELS_BRIEF_SVG
      puts "Generating #{f}"
      sh "railroad -bilamM | dot -Tsvg > #{f}"
    end
    
  end
  
  namespace :controllers do

    desc 'Generates an SVG class diagram for all controllers.'
    task :complete do
      f = @CONTROLLERS_ALL_SVG
      puts "Generating #{f}"
      sh "railroad -ilC | neato -Tsvg > #{f}"
    end

    desc 'Generates an abbreviated SVG class diagram for all controllers.'
    task :brief do
      f = @CONTROLLERS_BRIEF_SVG
      puts "Generating #{f}"
      sh "railroad -bilC | neato -Tsvg > #{f}"
    end

  end

  desc 'Generates all SVG class diagrams.'
  task :all => ['diagram:models:complete', 'diagram:models:brief', 'diagram:controllers:complete', 'diagram:controllers:brief']

end
