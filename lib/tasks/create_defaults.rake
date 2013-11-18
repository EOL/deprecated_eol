desc 'Create the default model instances that need to be in the DB for the code to work properly.'
task :create_defaults => :environment do
  Activity.create_defaults
  CuratorLevel.create_enumerated
  NotificationFrequency.create_defaults
  SortStyle.create_defaults
  UserIdentity.create_defaults
  ViewStyle.create_defaults
end
