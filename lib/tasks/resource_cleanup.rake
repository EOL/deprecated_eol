namespace :resources do
  desc 'resources cleanup'
  task :resources_cleanup => :environment do
    puts "Started (#{Time.now})\n"
    deleted_resources_ids = DataPointUri.where('resource_id not in (select id from resources)').pluck('distinct resource_id')
    deleted_resources_ids.each do |resource_id|
      pretended_deleted_resource = Resource.new
      pretended_deleted_resource.id = resource_id # doesn't accept id as mass assignment ie cannot do Resource.new(id: 2)
      TraitBank.delete_resource(pretended_deleted_resource)
      DataPointUri.where(resource_id: resource_id).destroy_all
    end
  end
end