# Utility methods
require 'active_support'

module Ambling #:nodoc
  # Utility methods when generating the settings classes from the XML
  module Utils
    # Stores information about the settings as derived from the XML
    class SettingsSection
      attr_accessor :key, :comment, :values, :attributes
      
      def initialize(key, attributes=[])
        @key = key
        @comment = ""
        @values = ActiveSupport::OrderedHash.new
        @attributes = attributes
      end
      
      def inspect
        "<SettingsSection [:key => #{@key}, :comment => #{@comment.inspect}, :values => #{@values.inspect}, :attributes => #{@attributes.inspect}]"
      end
      
      # Generate the class code
      def to_class_s(indent = 0)
        cdef = "\n#\n##{@comment}\n#\nclass #{key.camelize}\n"
        cbody = "\ninclude Base\n\n"
        cbody << "VALUES = [#{@values.keys.collect {|k| ':' + k}.join(',')}]\n"
        cbody << "ATTRIBUTES = [#{@attributes.collect {|k| ':' + k}.join(',')}]\n" if !@attributes.empty?
        subclasses = []
        @values.each do |k,v|
          cbody << "#\n# #{v.comment}\n#\nattr_accessor :#{k}\n\n"
          subclasses << v if not v.values.empty?
        end
        @attributes.each do |a|
          cbody << "#\n# xml attribute\n#\nattr_accessor :#{a}\n\n"
        end
        subclasses.each do |sc|
          cbody << sc.to_class_s
        end
        indent(cdef, indent) + indent(cbody, indent + 2) + indent("\nend\n", indent)
      end
      
      # Indent the str n spaces
      def indent(str, n)
        str.split(/\n/).collect {|s| spaces(n) + s}.join("\n")
      end
      
      # I must be missing something, because it feels wrong that 
      # there isn't an easier way to generate spaces
      def spaces(n)
        (0..n-1).inject("") {|w,n| w+= " "}
      end
    end
    #
    # generate a ruby class from the amchart settings XML
    class SettingsGenerator
      # Turn the provided xml into a class for chart_type
      def generate(chart_type, xml)
        require 'xmlparser'
        @parser=XML::Parser.new
        class <<@parser
          # enable additional events
          attr_accessor :comment, :xmlDecl
        end
        
        current_section_data = section_data = SettingsSection.new("xml")
        section_data_stack = []
        current_element = nil
        last_element = nil
        # Sam Ruby has code that does something very much like this
        @parser.parse(xml) do |type, name, data|
          case type
          when XML::Parser::START_ELEM
            # name = element name  ; data = hash of attributes
            if not current_section_data.values[name]
              current_section_data.values[name] = SettingsSection.new(name, data ? data.keys : [])
            end
            section_data_stack << current_section_data
            current_section_data = current_section_data.values[name]
            current_element = name
            last_element = nil
          when XML::Parser::END_ELEM
            # name = element name  ; data = nil
            end_section_data = current_section_data
            current_section_data = section_data_stack.pop
            last_element = current_element
            current_element = nil
          when XML::Parser::COMMENT                           
            # name = nil           ; data = string
            if current_section_data.values.empty?
              current_section_data.comment = data
            else
              current_section_data.values[last_element].comment = data
            end
          end
        end
        
        top_level = section_data.values.first.last
        top_level.comment = section_data.comment if top_level.comment.blank?
        
        cdef = "# Auto generated from XML file\n"
        cef << "require 'ambling/base'\nmodule Ambling\n  class #{chart_type.to_s.camelize}\n"
        cdef << top_level.to_class_s(4)
        cdef << "\n  end\nend\n"
      end
    end
  end
end