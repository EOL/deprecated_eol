desc 'Repair the ancestry (ONLY) from existing hierarchy entries in Solr'
task :fix_solr_ancestry => :environment do
  FixSolrAncestry.site_search
end
