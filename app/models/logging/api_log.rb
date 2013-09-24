# Just stores some VERY simple information (such as IP address and params).  No relationships, obviously.
class ApiLog < LazyLoggingModel
  establish_connection("#{Rails.env}_logging")
  
  attr_accessible :request_ip, :request_uri, :method, :version, :format, :request_id, :key, :user_id
  
end
