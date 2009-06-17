if Rails.env.test? && ENV["METRICS"] == "true"
  require 'flay'
  require 'flog'
  require 'roodi'
  require 'roodi_task'
  require 'metric_fu'

  MetricFu::Configuration.run do |config|
    #define which metrics you want to use
    config.metrics  = [:churn, :saikuro, :stats, :flog, :flay, :reek, :roodi, :rcov]
    config.flay     = { :dirs_to_flay => ['app', 'lib']  } 
    config.flog     = { :dirs_to_flog => ['app', 'lib']  }
    config.reek     = { :dirs_to_reek => ['app', 'lib']  }
    config.roodi    = { :dirs_to_roodi => ['app', 'lib'] }
    config.saikuro  = { :output_directory => 'scratch_directory/saikuro', 
                        :input_directory => ['app', 'lib'],
                        :cyclo => "",
                        :filter_cyclo => "0",
                        :warn_cyclo => "5",
                        :error_cyclo => "7",
                        :formater => "text"} #this needs to be set to "text"
    config.churn    = { :start_date => "1 year ago", :minimum_churn_count => 10}
    config.rcov     = { :test_files => ['spec/**/*_spec.rb'],
                        :rcov_opts => ["--sort coverage", 
                                       "--no-html", 
                                       "--text-coverage",
                                       "--no-color",
                                       "--profile",
                                       "--rails",
                                       "--exclude /gems/,/Library/,spec"]}
  end


  desc "Analyze for code complexity"
  namespace :eol do
    namespace :quality do 
      task :flog do
        flog = Flog.new
        flog.flog_files ['app']
        threshold = 291 # We want this to be 40-80, depending on what we allow.

        bad_methods = flog.totals.select {|name, score| score > threshold }
        bad_methods.sort { |a,b| a[1] <=> b[1] }.each do |name, score|
          puts "%8.1f: %s" % [score, name]
        end

        raise "#{bad_methods.size} methods have a flog complexity > #{threshold}" unless bad_methods.empty?
      end

      desc "Analyze for code duplication"
      task :flay do
        threshold = 487 # We would like this to be between 25-60... every codebase is different.
        flay = Flay.new({:fuzzy => false, :verbose => false, :mass => threshold})
        flay.process(*Flay.expand_dirs_to_files(['app']))
        flay.report
        raise "#{flay.masses.size} chunks of code have a duplicate mass > #{threshold}" unless flay.masses.empty?
      end

      RoodiTask.new 'roodi', ['app/**/*.rb', 'lib/**/*.rb'], 'config/roodi.yml'

      desc "Runs metrics on EOL"
      task :all => [:flog, :flay, :roodi, 'metrics:all']
    end
  end
end
