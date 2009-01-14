class ExternalLinkLog < LoggingModel
  
  validates_presence_of :external_url
  
  # A possibly-geocoding reference to a single IPv4 address.
  belongs_to :ip_address
  validates_presence_of :ip_address_raw # 32-bit integer representation
  
  # A user ID will be recorded iff the user is logged in to a normal account.
  belongs_to :user
  
  # A string of client-side information provided by the web browser.
  validates_presence_of :user_agent

  def before_validation
    self.ip_address_raw = self.ip_address.number if self.ip_address and not self.ip_address_raw
    true # continue validation, as normal
  end

  def self.log(external_url, request, user)
     if DataObjectLog.data_logging_enabled?
       return nil if external_url.blank? or request.nil? or user.nil?

       opts = {
         :ip_address_raw => IpAddress.ip2int(request.remote_ip),
         :user_agent => request.user_agent,
         :path => request.referer,
         :external_url => external_url
       }
       opts[:user_id] = user.id unless user.nil?
       ExternalLinkLog.create(opts)
     end
  end
   
end