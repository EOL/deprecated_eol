# Represents a single view event for a given +DataObject+. Each instance 
#
# Author: Preston Lee <preston.lee@openrain.com>
class DataObjectLog < LoggingModel
  
  # The object whose use we are logging.
  belongs_to :data_object
  validates_presence_of :data_object
    
  # This is a property of the DataObject and is therefore redundant,
  # however, it is useful for mining purposes in that we can avoid a
  # cross-database join since DataObjects themselves are not stored in the logging database. 
  belongs_to :data_type
  validates_presence_of :data_type
  
  # A possibly-geocoding reference to a single IPv4 address.
  belongs_to :ip_address
  validates_presence_of :ip_address_raw # 32-bit integer representation

  # A user ID will be recorded iff the user is logged in to a normal account.
  belongs_to :user
  
  # A string of client-side information provided by the web browser.
  validates_presence_of :user_agent

  # while mining this table, we often add a .total column ... we expect it to return an integer
  def total
    self.attributes['total'].to_i
  end

  def before_validation
    self.data_type = data_object.data_type unless self.data_type_id or self.data_type or not self.data_object_id
    self.ip_address_raw = self.ip_address.number if self.ip_address and not self.ip_address_raw
    true # continue validation, as normal
  end

  class << self
    attr_accessor :data_logging_enabled
    def data_logging_enabled?
      self.data_logging_enabled != false # will return true for anything but false, including nil!
    end
  end
  
  # Creates log events (instances of this class) for the given +DataObject(s)+
  # and the given client/user information. The first parameter must be either a
  # single instance or array or instances. Example usage:
  #
  # Usage:
  #   DataObjectLog.log [data_object, data_object], rails_request, user, taxon_concept
  #
  # For now, we assume that all of the object passed in refer to a particular
  # user, came from a particular rails request, and refer to a particular taxon_concept
  def self.log data_objects, request, user, taxon_concept
    if DataObjectLog.data_logging_enabled?
      return nil if data_objects.nil? or request.nil? or user.nil? # allow nil taxon_concept, atleast for now.  maybe not all data object views refer to a TC?
      taxon_concept = taxon_concept.id if taxon_concept.is_a?TaxonConcept
      
      data_objects=[data_objects] unless data_objects.is_a?Array  # turn a singleton into an array
      
      data_objects.compact! 
      # ... add referrer?  hmm ... string would be a whole lot of data ... would it be useful for mining?  more useful than Google Analytics?
      opts = {
        :ip_address_raw => IpAddress.ip2int(request.remote_ip),
        :user_agent => request.user_agent,
        :path => request.request_uri
      }
      opts[:user_id] = user.id unless user.nil?
      
      # We'll log an event for each item in the array.
      result = []
      DataObjectLog.transaction do
        data_objects.each do |obj|
          agent_id = obj.data_supplier_agent.nil? ? (obj.agents.first.nil? ? 0 : obj.agents.first.id) : obj.data_supplier_agent.id
          result << create_log(obj, opts.merge({ :agent_id => agent_id, :taxon_concept_id => taxon_concept }))
        end
      end

      return result
    end
  end
  
  private

  def self.create_log(obj, opts)
    logger.warn('Bogus invokation of DataObject creation function!') and return if obj.nil? or opts.nil? or obj.class != DataObject or opts.class != Hash
    l = DataObjectLog.new opts
    # Use 'data_type_id' instead of 'data_type.id' to avoid a lazy SQL load.
    l.data_object_id ||= obj.id
    l.data_type_id ||= obj.data_type_id
    l.save
    l
  end
  
end
