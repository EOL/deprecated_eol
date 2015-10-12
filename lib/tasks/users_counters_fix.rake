
namespace :user_counters do

  desc 'Fix counters culture for users table'
  task :fix_counters => :environment do
    Comment.counter_culture_fix_counts
    UsersDataObject.counter_culture_fix_counts
    UserAddedData.counter_culture_fix_counts
    WikipediaQueue.counter_culture_fix_counts
  end
end
