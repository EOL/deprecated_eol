class SanitizeText < ActiveRecord::Migration
  def self.up
    # sanitize data objects
    puts "Sanitize data objects"
    DataObject.all.each do |data_object|
      data_object.description = Sanitize.clean(data_object.description.balance_tags, Sanitize::Config::RELAXED)
      data_object.object_title = Sanitize.clean(data_object.object_title.balance_tags, Sanitize::Config::RELAXED)
      data_object.save
    end
    
    # sanitize collections
    puts "Sanitize collections"
    Collection.all.each do |coll|
      coll.name = Sanitize.clean(coll.name.balance_tags, Sanitize::Config::RELAXED)
      coll.description = Sanitize.clean(coll.description.balance_tags, Sanitize::Config::RELAXED)
      coll.save
    end
    
    # sanitize communities
    puts "Sanitize Communities"
    Community.all.each do |comm|
      comm.name = Sanitize.clean(comm.name.balance_tags, Sanitize::Config::RELAXED)
      comm.description = Sanitize.clean(comm.description.balance_tags, Sanitize::Config::RELAXED)
      comm.save
    end
    
    # sanitize comments
    puts "Sanitize Comments"
    Comment.all.each do |comm|
      comm.body = Sanitize.clean(comm.body.balance_tags, Sanitize::Config::RELAXED)
      comm.save
    end
  end

  def self.down
    # Doesn't really matter.
  end
end
