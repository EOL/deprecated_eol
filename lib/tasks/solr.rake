require 'escape'

namespace :solr do
  desc 'Start the Solr instance'
  task :start => :environment do
    puts "** Starting Background Solr instance for EOL..."
    if RUBY_PLATFORM =~ /w(in)?32$/
      abort('This command does not work on Windows. Please use rake solr:run to run Solr in the foreground.')
    end
    port = $SOLR_SERVER.gsub(/^.*:(\d+).*$/, '\\1')
    FileUtils.cd(File.join($SOLR_DIR)) do
      command = [Rails.root.join('bin', 'solr'), 'start', '--', '-p', port]
      if $SOLR_SERVER_RAM
        command << '-r'
      end
      if $SOLR_DIR
        command << '-s' << $SOLR_DIR
      end
      system(Escape.shell_command(command.map {|p| p.to_s}))
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
    command = [Rails.root.join('bin', 'solr'), 'run', '--', '-p', port.to_s]
    if $SOLR_SERVER_RAM
      command << '-r'
    end
    if $SOLR_DIR
      command << '-s' << $SOLR_DIR
    end
    exec(command.join(" "))
  end

  desc 'Stop the Solr instance'
  task :stop => :environment do
    puts "** Stopping Background Solr instance for EOL..."
    FileUtils.cd($SOLR_DIR) do
      exec([Rails.root.join('bin', 'solr'), 'stop'].join(" "))
    end
    File.delete(Rails.root.join('solr', 'solr', 'eol-solr.pid'))
  end

  desc 'Rebuild the data objects index'
  task :rebuild_all  => :environment do |t, args|
    puts "\n\nRebuilding DataObjects ...\n"
    EOL::Solr.rebuild_all
    puts "Complete\n\n"
  end

  desc 'Rebuild the data objects index'
  task :rebuild_data_objects, [:data_object_id]  => :environment do |t, args|
    puts "\n\nPreparing and POSTing data_object XML document(s)...\n"
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
    puts "Complete\n\n"
  end

  desc 'Rebuild the site_search index'
  task :rebuild_site_search => :environment do
    puts "\n\nPreparing and POSTing XML document(s)...\n"
    EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
    puts "Complete\n\n"
  end

  desc 'Rebuild the collection_items index'
  task :rebuild_collection_items => :environment do
    EOL::Solr::CollectionItemsCoreRebuilder.begin_rebuild
  end

  desc 'Rebuild the bhl index'
  task :rebuild_bhl => :environment do
    builder = EOL::Solr::BHLCoreRebuilder.new()
    builder.begin_rebuild
  end

  desc 'Rebuild the ENTIRE activity_logs index with only comments'
  task :rebuild_comments_activity_log => :environment do
    solr = SolrAPI.new($SOLR_SERVER, $SOLR_ACTIVITY_LOGS_CORE)
    solr.obliterate
    EOL::Solr::ActivityLog.rebuild_comments_logs
  end

  desc 'Remove watch collection logs from activity_logs index'
  task :remove_watch_collection_activity_logs => :environment do
    EOL::Solr::ActivityLog.remove_watch_collection_logs
  end

  desc 'Destroy all indices'
  task :destroy => :environment do
    solr = SolrAPI.new($SOLR_SERVER, $SOLR_TAXON_CONCEPTS_CORE)
    solr.obliterate
    solr = SolrAPI.new($SOLR_SERVER, $SOLR_DATA_OBJECTS_CORE)
    solr.obliterate
    solr = SolrAPI.new($SOLR_SERVER, $SOLR_SITE_SEARCH_CORE)
    solr.obliterate
    solr = SolrAPI.new($SOLR_SERVER, $SOLR_COLLECTION_ITEMS_CORE)
    solr.obliterate
    solr = SolrAPI.new($SOLR_SERVER, $SOLR_ACTIVITY_LOGS_CORE)
    solr.obliterate
    solr = SolrAPI.new($SOLR_SERVER, $SOLR_BHL_CORE)
    solr.obliterate
  end
end
