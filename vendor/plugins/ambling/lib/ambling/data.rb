# Classes to store Amcharts data and generate data xml
require 'ambling/base'

module Ambling #:nodoc
  
  class Data
    #
    # Build the xml with the class name in lower case
    class Base
      def tag_name
        self.class.to_s.split("::").last.downcase
      end
      
      def to_xml
        builder = Builder::XmlMarkup.new
        builder.tag!(tag_name) { self.build_xml(builder) }
        builder.target!
      end
    end
    
    # A data point in the XML has a value and attributes
    class BaseValue
      attr_accessor :attributes, :value
      
      def initialize(value, attributes={})
        @value = value
        @attributes = attributes
      end
      
      def to_xml
        builder = Builder::XmlMarkup.new
        build_xml(builder)
        builder.target!
      end
      
      def tag_name
        "value"
      end
      
      def build_xml(builder)
        builder.tag!(tag_name, @value, @attributes)
      end
    end
    
    # Build the XML for a message slightly differently
    class Message < BaseValue
      def build_xml(builder)
        builder.message(@attributes){|message| message.cdata! @value}
      end
    end
    
    # <value foo="bar">
    class Value < BaseValue
    end
    
    # <slice foo="bar">
    class Slice < BaseValue
      def tag_name
        "slice"
      end
    end
    
    # <point foo="bar">
    # points don't have values
    class Point < BaseValue
      def initialize(attributes = {})
        @value, @attributes = "", attributes
      end
      
      def tag_name
        "point"
      end
    end
    
    # Holds an array of values
    class BaseValueHolder < Base
      attr_reader :values, :attributes
      
      def initialize(data = [], attributes = {})
        self.values = data
        @attributes = attributes
      end
      
      def values=(data)
        @values = []
        data.each {|item| self.push(item)}
      end
      
      def push(item)
        if item.is_a?(Value)
          @values << item
        else
          @values << Value.new(item, {:xid => @values.size+1})
        end
      end
      
      alias :<< :push
      
      def build_xml(builder)
        @values.each { |value| value.build_xml(builder) }
      end
    end
    
    # A series is nothing but an array of values
    class Series < BaseValueHolder
    end
    
    # Line and Column graphs are very similar because they both contain values
    class LineColumnGraph < BaseValueHolder
      def tag_name
        "graph"
      end
    end
    
    # line graph
    class LineGraph < LineColumnGraph
    end
    
    # column graph
    class ColumnGraph < LineColumnGraph
    end
    
    # xy graphs contain points, not values
    # I know I should abstract the BaseValueHolder to handle a generic array of Values.
    # Unfortunately, I don't have time right now
    class XyGraph
      attr_reader :points
      
      def initialize(data = [])
        self.points = data
      end
      
      def points=(data)
        @points = []
        data.each {|item| self.push(item)}
      end
      
      def push(item)
        if item.is_a?(Point)
          @points << item
        else
          @points << Point.new(item)
        end
      end
      
      alias :<< :push
      
      def build_xml(builder)
        @points.each { |point| point.build_xml(builder) }
      end
      
    end
    
    # Data files always have an optional message
    class BaseData < Base
      attr_reader :message

      def message=(data)
        if data.is_a?(Message)
          @message = data
        else
          @message = Message.new(data)
        end
      end
      
    end
    
    # Line and Column Data have a single series and a number of graphs
    class LineColumnChart < BaseData
      attr_reader :series, :graphs
      
      def initialize
        @series, @graphs = Series.new, []
      end
      
      def series=(data)
        if data.is_a?(Series)
          @series = data
        else
          @series.values = data
        end
      end
      
      def build_xml(builder)
        @message.build_xml(builder) if !@message.nil?
        builder.series {|series| @series.build_xml(series)}
        builder.graphs do |graphs|
          @graphs.each_with_index {|g,i| graphs.graph({:gid => i+1}.merge(g.attributes)) {|graph| g.build_xml(graph)}}
        end
      end
      
      def tag_name
        "chart"
      end
    end
    
    # For an amchart line chart
    class LineChart < LineColumnChart
    end
    
    # For an amchart column chart
    class ColumnChart < LineColumnChart
    end
    
    # For an amchart xy (line) chart
    class XyChart < BaseData
      attr_reader :graphs
      
      def initialize
        @graphs = []
      end
      
      def build_xml(builder)
        @message.build_xml(builder) if !@message.nil?
        builder.graphs do |graphs|
          @graphs.each_with_index {|g,i| graphs.graph({:gid => i}) {|graph| g.build_xml(graph)}}
        end
      end
      
      def tag_name
        "chart"
      end
      
    end
    
    # For an amchart pie chart
    class Pie < BaseData
      attr_reader :slices
      
      def initialize(data = [])
        self.slices = data
      end
      
      def slices=(data)
        @slices = []
        data.each {|item| self.push(item)}
      end
      
      def push(item)
        if item.is_a?(Slice)
          @slices << item
        else
          @slices << Slice.new(item)
        end
      end
      
      alias :<< :push
      
      def build_xml(builder)
        @message.build_xml(builder) if !@message.nil?
        @slices.each {|s| s.build_xml(builder)}
      end
    end
  end
end