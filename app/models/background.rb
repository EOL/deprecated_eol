# NOTE: this class is for debugging ONLY, it's not used in the code.
class Background
  SIZE_LIMIT = 25_000
  class << self
    def size(queue)
      Resque.size(queue)
    end

    def stop_top_images
      Resque::Job.destroy(:php, CodeBridge, {"cmd"=>"top_images"})
    end

    def stop_notifications
      Resque::Job.destroy(:notifications, PrepareAndSendNotifications)
    end

    def stop_hierarchies
      Resque::Job.destroy(:notifications, HierarchyReindexing)
    end

    def stop_reindexing
      things = Resque.peek(:php, 0, SIZE_LIMIT)
      things.select { |t| t["args"].first["cmd"] == "reindex_taxon_concept" }.
             each { |t| Resque::Job.destroy(:php, CodeBridge, t["args"].first) }
    end

    def stop_duplicates(queue)
      things = Resque.peek(queue, 0, SIZE_LIMIT)
      stuff = {}
      things.each do |t|
        a = t["args"].first
        stuff.has_key?(a) ?
          Resque::Job.destroy(:php, CodeBridge, a) :
          stuff[a] = true
      end
      true
    end

    def count_job_types(queue)
      items = Resque.peek(queue, 0, SIZE_LIMIT)
      items.group_by { |e| e["class"] }.each { |c,i| puts "#{c} = #{i.size}" }
      true
    end

    def count_codebridge_types(queue)
      items = Resque.peek(queue, 0, SIZE_LIMIT)
      items.select { |i| i["class"] == "CodeBridge" }.
        group_by { |i| i["args"].first["cmd"] }.
        each { |c,i| puts "#{c} = #{i.size}" }
      true
    end
  end
end
