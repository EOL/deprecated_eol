desc 'Run sundry tasks for a staging deploy for clearing various caches, migrating, and the like.'
task :clear_and_migrate => :environment do
  # NOTE - I'm skipping assets because they seem to happen in a separate capistrano task and I can't force them to run here... don't want duplication!
  # NOT YET - Rake::Task['assets:precompile'].invoke
  # NOT YET - Rake::Task['assets:clean_expired'].invoke
  Rake::Task['log:clear'].invoke
  Rake::Task['db:migrate'].invoke
  Rake::Task['cache:clear'].invoke
  puts "Assets compiled, cleaned; log cleared; db migrated; cache cleared."
end
