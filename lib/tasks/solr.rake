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
      command = ["#{RAILS_ROOT}/bin/solr", 'start', '--', '-p', port.to_s]
      if $SOLR_SERVER_RAM
        command << '-r'
      end
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
    command = ["#{RAILS_ROOT}/bin/solr", 'run', '--', '-p', port.to_s]
    if $SOLR_SERVER_RAM
      command << '-r'
    end
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

  desc 'Rebuild the data objects index'
  task :rebuild_all  => :environment do |t, args|
    puts "\n\nRebuilding DataObjects ...\n"
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
    puts "Rebuilding SiteSearch ...\n"
    EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
    puts "Rebuilding CollectionItems ...\n"
    EOL::Solr::CollectionItemsCoreRebuilder.begin_rebuild
    puts "Rebuilding BHL ...\n"
    builder = EOL::Solr::BHLCoreRebuilder.new()
    builder.begin_rebuild
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

  desc 'Rebuild a site_search resource tyoe'
  task :rebuild_site_search_resource_type, [:resource_type] => :environment do |t, args|
    if args[:resource_type].blank?
      puts "\n\n    rake solr:rebuild_site_search_resource_type[ClassName]"
      return
    end
    klass = args[:resource_type].constantize
    solr_api = EOL::Solr::SiteSearchCoreRebuilder.connect
    EOL::Solr::SiteSearchCoreRebuilder.reindex_model(klass, solr_api)
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


end
