module EOL
  module ActivityLogItem
    def log_date
      if self.is_a? UsersDataObject
        if self.data_object.updated_at >= (self.data_object.created_at + 2.minutes)
          return self.data_object.updated_at
        else
          return self.data_object.created_at
        end
      else
        return self.created_at
      end
    end
  end
end
