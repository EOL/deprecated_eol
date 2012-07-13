namespace :peer_sites do

  desc 'Run any Solr updates from other peers'
  task :update_solr => :environment do
    while true
      puts "Checking for new updates"
      EOL::PeerSites::SolrUpdater.update()
      # we'll check every 5 seconds
      sleep(5)
    end
  end

end
