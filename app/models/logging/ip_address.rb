require 'ipaddr'

class IpAddress < LoggingModel

  before_validation :set_provider_if_null

  has_many :data_object_logs
  has_many :search_logs

  # these fields are required in the database 
  # and they don't require successful geocoding
  #
  validates_presence_of     :number
  validates_numericality_of :number

  # NO VALIDATIONS - we want to allow for this data
  #                  to be blank to ease the logging 
  #                  process and *cache* the fact that 
  #                  certain IpAddresses come back 
  #                  blank when attempting to be geocoded

  # validates_presence_of :country_code
  # validates_presence_of :provider
  # validates_presence_of :latitude
  # validates_presence_of :longitude
  
  # Converts an IPv4 address string to a 32-bit integer which can be stored in an ordinary 4-byte database integer column without truncation or decimal points.
  def self.ip2int(ip)
    ip ||=  '127.0.0.1'
    IPAddr.new(ip, Socket::AF_INET).to_i
  end
  
  # Converts a 32-bit integer to a human-readable IP address string in dotted decimal form.  
  def self.int2ip(int = ip2int())
    IPAddr.new(int, Socket::AF_INET).to_s
  end
  
  protected

  def set_provider_if_null
    self.provider = '' unless self.provider   # database requires this field 
                                              # but we want it to be OK for it 
                                              # to be an empty string
  end

end
