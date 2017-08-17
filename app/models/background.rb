# NOTE: this class is for debugging ONLY, it's not used in the code.
class Background
  SIZE_LIMIT = 25_000
  class << self
    def send_new_user_emails
      Rails.logger.warn("## #send_new_user_emails")
      users = User.where(["validation_code = ? AND created_at > ?", "", 1.hour.ago])
      Rails.logger.warn("** Found #{users.size} users...")
      users.each do |user|
        url =  "http://eol.org/users/#{user.id}/verify/#{user.validation_code}"
        Rails.logger.warn("** User #{user.id} (#{user.full_name})...")
        Notifier.user_verification(user, url).deliver
      end
    end

    def size(queue)
      Resque.size(queue)
    end

    def in_queue?(queue, klass, key, value)
      begin
        ! Resque.peek(queue, 0, 20_000).
                 select { |j| j["class"] == klass.to_s &&
                   j["args"].first[key.to_s] &&
                   j["args"].first[key.to_s] == value }.
                 empty?
      rescue => e
        EOL.log("WARNING: Failed to read '#{queue}' queue: #{e.message}",
          prefix: "!")
        false
      end
    end

    def top_images_in_queue?
      in_queue?(:php, CodeBridge, "cmd", "top_images")
    end

    def stop_top_images
      Resque::Job.destroy(:php, CodeBridge, {"cmd"=>"top_images"})
    end

    def stop_notifications
      Resque::Job.destroy(:notifications, PrepareAndSendNotifications)
    end

    def stop_hierarchy_reindexing
      Resque::Job.destroy(:harvesting, HierarchyReindexing)
    end

    def stop_php_reindexing
      things = Resque.peek(:php, 0, SIZE_LIMIT)
      things.select { |t| t["args"].first["cmd"] == "reindex_taxon_concept" }.
             each { |t| Resque::Job.destroy(:php, CodeBridge, t["args"].first) }
    end

    def stop_duplicates(queue)
      things = Resque.peek(queue, 0, SIZE_LIMIT)
      stuff = {}
      count = 0
      things.each do |t|
        a = t.dup
        a.delete("id")
        stuff.has_key?(a) ?
          Resque::Job.destroy(queue, CodeBridge, a) && count += 1 :
          stuff[a] = true
      end
      count
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
