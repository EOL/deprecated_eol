require 'ipaddr'

class IpAddress < LoggingModel

  has_many :data_object_logs
  has_many :search_logs

  validates_presence_of :country_code
  
  validates_presence_of :number
  validates_numericality_of :number
  
  validates_presence_of :provider
  validates_presence_of :latitude
  validates_presence_of :longitude
  
  # Converts an IPv4 address string to a 32-bit integer which can be stored in an ordinary 4-byte database integer column without truncation or decimal points.
  def self.ip2int(ip = '127.0.0.1')
    IPAddr.new(ip, Socket::AF_INET).to_i
  end
  
  # Converts a 32-bit integer to a human-readable IP address string in dotted decimal form.  
  def self.int2ip(int = ip2int())
    IPAddr.new(int, Socket::AF_INET).to_s
  end
  
end
