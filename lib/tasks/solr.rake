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

  desc 'Build the Solr indexes based on the existing TaxonConcepts'
  # TODO - when we have other indexes, we may want sub-tasks to do TCs, Tags, images, and whatever else...
  task :build => 'solr:start' do
    require 'solr_api'
    solr = SolrAPI.new($SOLR_SERVER, $SOLR_TAXON_CONCEPTS_CORE)
    puts "** Deleting all existing entries..."
    solr.delete_all_documents
    puts "** Creating indexes..."
    count = TaxonConcept.count
    puts "** You have #{count} Taxon Concepts.  In the interest of time, this task will only add the first 100." if 
      count > 100
    solr.build_indexes(TaxonConcept.all[0..99])
  end
  
  desc 'Build the elevate.xml file using Search Suggestions'
  task :build_concept_elevate => :environment do
    suggestions = SearchSuggestion.find(:all, :select => 'term, taxon_id', :order => 'term ASC, sort_order DESC')
    
    taxon_concept_elevate_path = File.join(RAILS_ROOT, 'solr', 'solr', 'data', 'taxon_concepts', 'elevate.xml')
    File.open(taxon_concept_elevate_path, 'w') do |f|
      f.write("<?xml version='1.0' encoding='UTF-8' ?>\n")
      f.write("<elevate>\n")
      unless suggestions.empty?
        last_suggestion = nil
        suggestions.each do |s|
          if last_suggestion.nil? || last_suggestion.term != s.term
            unless last_suggestion.nil?
              f.write("  </query>\n")
            end
            f.write("  <query text='#{s.term}'>\n")
          end
          f.write("    <doc id='#{s.taxon_id}'/>\n")
          last_suggestion = s
        end
        f.write("  </query>\n")
      end
      f.write("</elevate>\n")
    end
  end
  
  desc 'Rebuild the site_search index'
  task :rebuild_site_search => :environment do
    builder = EOL::Solr::SiteSearchCoreRebuilder.new()
    builder.obliterate
    builder.begin_rebuild
  end
  
  desc 'Rebuild a site_search resource tyoe'
  task :rebuild_site_search_resource_type, [:resource_type] => :environment do |t, args|
    if args[:resource_type].blank?
      puts "\n\n    rake solr:rebuild_site_search_resource_type[ClassName]"
      return
    end
    klass = args[:resource_type].constantize
    builder = EOL::Solr::SiteSearchCoreRebuilder.new()
    builder.reindex_model(klass)
  end
  
  desc 'Rebuild the collection_items index'
  task :rebuild_collection_items => :environment do
    builder = EOL::Solr::CollectionItemsCoreRebuilder.new()
    builder.begin_rebuild
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
