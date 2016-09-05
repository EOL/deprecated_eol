namespace :resources do
  desc 'resources cleanup'
  task :resources_cleanup => :environment do
    puts "Started (#{Time.now})\n"
    deleted_resources_ids = DataPointUri.where('resource_id not in (select id from resources)').pluck('distinct resource_id').take(1)
    deleted_resources_ids.each do |resource|
      pretended_deleted_resources = Resource.new
      pretended_deleted_resources.id = resource #doesn't accept id as mass assignment ie cannot do Resource.new(id: 2)
      TraitBank.delete_resource(pretended_deleted_resources)
      DataPointUri.where(resource_id: resource).destroy_all
    end
  end
end