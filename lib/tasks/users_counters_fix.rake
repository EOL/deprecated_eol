
namespace :user_counters do

  desc 'Fix counters culture for users table'
  task :fix_counters => :environment do
    #fix total number of comments in User table
    Comment.counter_culture_fix_counts
    #fix articles total count
    UsersDataObject.counter_culture_fix_counts
    #fix data submitted by the user
    UserAddedData.counter_culture_fix_counts
    #fix wikipedia queue by the user
    WikipediaQueue.counter_culture_fix_counts
  end
end
