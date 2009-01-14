# Base module for settings
require 'builder'
require 'active_support'

# the version of builder that comes with activesupport-1.4.4 is busted for builder.tag!(:y)
# patch with tag! from builder 2.1.2
module Builder
  class XmlBase
    def tag!(sym, *args, &block)
      method_missing(sym.to_sym, *args, &block)
    end
  end
end
module Ambling #:nodoc
  # debugging
  # class BaseLogger
  #   cattr_accessor :logger, :instance_writer => false
  # end
  
  #
  # All settings classses include these base functions that populate
  # the data from a hash and generate the xml
  #
  module Base
    def initialize(hash = {})
      populate(hash)
    end
    
    #
    # populate the settings with data from the hash
    #
    def populate(hash = {})
      hash.each do |k,v|
        val = if v.is_a?(Hash)
          klass = self.class.const_get(k.to_s.camelize)
          klass.new(v)
        elsif v.is_a?(Array)
          klass = self.class.const_get(k.to_s.camelize)
          v.collect {|i| klass.new(i)}
        else
          v
        end
        self.send("#{k}=", val)
      end
    end
    
    #
    # Return an xml representation of these settings
    #
    def to_xml
      builder = Builder::XmlMarkup.new
      tag = self.class.to_s.split("::").last.downcase
      attr_list = self.class.send(:const_get, :ATTRIBUTES) rescue []
      attrs = attr_list.inject({}) do |h,a|
        val = self.send(a)
        val.nil? ? h : h.merge(a => val)
      end
      builder.tag!(tag, attrs) { self.build_xml(builder) }
      builder.target!
    end
    
    #
    # build an xml representation of this subcomponent of the settings using the provided builder
    #
    def build_xml(builder)
      self.class.send(:const_get, :VALUES).each do |a|
        val = self.send(a)
        if val.respond_to? :build_xml
          builder.tag!(a) {|b| val.build_xml(b) }
        elsif val.is_a? Array
          val.each {|v| builder << v.to_xml }
        elsif not val.nil?
          builder.tag! a, val
        end
      end
    end
  end
end
