desc 'Ensures that all activity types exist in the database.'
task :create_activities => :environment do
  Activity.create_defaults
end
