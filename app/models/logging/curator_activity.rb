class CuratorActivity < LoggingModel
  
  has_many :curator_activity_logs
  
  validates_presence_of :code
  validates_uniqueness_of :code

  class << self
    # CuratorActivity.approve type shortcuts for often-used activities - might get rid of this, we'll see if it's useful
    def method_missing_with_curator_activity_code_shortcuts name, *args
      return method_missing_without_curator_activity_code_shortcuts(name, *args) if name.to_s.starts_with?'find_'

      if name.to_s.ends_with?'!'
        activity = CuratorActivity.find_or_create_by_code name.to_s.sub(/!$/,'')
      else
        activity = CuratorActivity.find_by_code name.to_s
      end

      if activity
        return activity
      else
        begin
          method_missing_without_curator_activity_code_shortcuts name, *args
        rescue NoMethodError
          raise ActiveRecord::RecordNotFound.new("Couldn't find CuratorActivity with code=#{name}")
        end
      end
    end
    alias_method_chain :method_missing, :curator_activity_code_shortcuts
  end
  
end
