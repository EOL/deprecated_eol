# ActivityLog reads from curator_activity_logs, comments, users_data_objects,
# collection_activity_logs, community_activity_logs ...Note that EVERY table should have a user_id associated
# with it, as well as a foreign key to ... something it affected... as well as another FK to the Activity table
# explaining what kind of activity took place (and, thus, which partial to render).
module EOL

  class ActivityLog

    include Enumerable

    def self.find(activity_log, options = {})
      ActivityLog.new(activity_log, options)
    end

    def initialize(source, options = {})
      @source       = source
      @klass        = source.class.name
      @id           = source.id
      @activity_log = []
      find_activities(@klass, @source, options)
      # TODO - it would make more sense to move this to the source models, passed in as an argument to some call that
      # makes the class loggable.
      # TODO - error-checking (for example, what if created_at is nil or not available?):
      @activity_log = @activity_log.sort_by {|l| l.class == UsersDataObject ? l.data_object.created_at : l.created_at }
    end

    def find_activities(klass, source, options = {})
      case klass
      when "User"
        if options[:news]
          @activity_log += Comment.find_all_by_parent_id_and_parent_type(source.id, "User")
          # TODO - Whoa.  WHOA.  Seriously?!?  No.  You NEED to make this faster.  Seriously.
          source.watch_collection.collection_items.each do |item|
            find_activities(item.object_type, item.object) # Note NO options to avoid infinite recursion
          end
        else
          user_activities(source)
        end
      when "Community"
        community_activities(source)
      when "DataObject"
        data_object_activities(source)
      when "TaxonConcept"
        taxon_concept_activities(source)
      else # Anything else that you make loggable will track comments and ONLY comments:
        other_activities(source)
      end
    end

    def user_activities(source)
      @activity_log += CuratorActivityLog.find_all_by_user_id(source.id)
      @activity_log += Comment.find_all_by_user_id(source.id)
      @activity_log += UsersDataObject.find_all_by_user_id(source.id, :include => :data_object)
      @activity_log += CollectionActivityLog.find_all_by_user_id(source.id)
      @activity_log += CommunityActivityLog.find_all_by_user_id(source.id)
    end

    def community_activities(source)
      @activity_log += Comment.find_all_by_parent_id_and_parent_type(source.id, "Community")
      @activity_log += CollectionActivityLog.find_all_by_collection_id(source.focus.id)
      @activity_log += CommunityActivityLog.find_all_by_community_id(source.id)
    end

    def data_object_activities(source)
      @activity_log += CuratorActivityLog.find_all_by_changeable_object_type_id_and_object_id(
        ChangeableObjectType.data_object.id, source.id
      )
      @activity_log += Comment.find_all_by_parent_id_and_parent_type(source.id, "DataObject")
      @activity_log += UsersDataObject.find_all_by_data_object_id(source.id, :include => :data_object)
    end

    def taxon_concept_activities(source)
      @activity_log += CuratorActivityLog.find_all_by_data_objects_on_taxon_concept(source)
      @activity_log += Comment.all_by_taxon_concept_recursively(source)
      @activity_log += UsersDataObject.find_all_by_taxon_concept_id(source.id, :include => :data_object)
    end

    def other_activities(source)
      @activity_log += Comment.find_all_by_parent_id_and_parent_type(source.id, source.class.name)
    end

    #
    # Basically, the rest of the functions here are simply implementing Enumerable.  You can probalbly skip reading
    # these, but start reading again at the "private" keyword--there are plenty of methods there that you may want to
    # know about.
    #

    def [] which
      @activity_log[which]
    end

    def +(other)
      if other.is_a? Array
        @activity_log += other
      else # assume it's a activity_log
        @activity_log += other.items
      end
    end

    def items
      @activity_log
    end

    def count
      @activity_log.count
    end

    def length
      @activity_log.length
    end

    def blank?
      @activity_log.blank?
    end

    def each
      @activity_log.each {|fi| yield(fi) }
    end

    def empty?
      @activity_log.empty?
    end

    def first
      @activity_log.first
    end

    def last
      @activity_log.last
    end

    def nil?
      @activity_log.nil?
    end

  end
end
