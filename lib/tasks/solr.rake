require 'escape'

namespace :solr do
  desc 'Start the Solr instance'
  task :start => :environment do
    puts "** Starting Background Solr instance for EOL..."
    if RUBY_PLATFORM =~ /w(in)?32$/
      abort('This command does not work on Windows. Please use rake sunspot:solr:run to run Solr in the foreground.')
    end
    port = $SOLR_SERVER
    port.gsub!(/^.*:(\d+).*$/, '\\1')
    FileUtils.cd(File.join($SOLR_DIR)) do
      command = ["#{RAILS_ROOT}/bin/solr", 'start', '--', '-p', port.to_s] #, '-d', data_path]
      if $SOLR_DIR
        command << '-s' << $SOLR_DIR
      end
      system(Escape.shell_command(command))
    end
  end

  desc 'Run the Solr instance in the foreground'
  task :run => :environment do
    puts "** Starting Foreground Solr instance for EOL..."
    if RUBY_PLATFORM =~ /w(in)?32$/
      abort('This command does not work on Windows.')
    end
    # data_path = Sunspot::Rails.configuration.data_path
    # FileUtils.mkdir_p(data_path)
    port = $SOLR_SERVER
    port.gsub!(/^.*:(\d+).*$/, '\\1')
    command = ["#{RAILS_ROOT}/bin/solr", 'run', '--', '-p', port.to_s] #, '-d', data_path]
    if $SOLR_DIR
      command << '-s' << $SOLR_DIR
    end
    exec(Escape.shell_command(command))
  end

  desc 'Stop the Solr instance'
  task :stop => :environment do
    puts "** Stopping Background Solr instance for EOL..."
    FileUtils.cd($SOLR_DIR) do
      system(Escape.shell_command(["#{RAILS_ROOT}/bin/solr", 'stop']))
    end
  end
end
