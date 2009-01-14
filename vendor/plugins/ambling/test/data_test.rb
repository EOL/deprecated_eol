$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'test/unit/xml'
require 'ambling'
require 'test_helper'

class DataTest < Test::Unit::TestCase    
  include TestHelper
  
  def setup
    super
    @simple_chart_xml = read_and_strip_xml_file "simple_chart_data.xml"
    @advanced_chart_xml = read_and_strip_xml_file "advanced_chart_data.xml"
    @simple_pie_xml = read_and_strip_xml_file "simple_pie_data.xml"
  end
  
  
  def test_line_column_chart_to_xml
    simple_chart = Ambling::Data::LineChart.new
    simple_chart.message = "Test Broadcast"
    simple_chart.series = [10,20,30]
    simple_chart.graphs << Ambling::Data::LineGraph.new([100,200,300])
    
    assert_xml_equal @simple_chart_xml, simple_chart.to_xml,
      "Expected |#{@simple_chart_xml}| but was |#{simple_chart.to_xml}|"
    
    simple_chart = Ambling::Data::ColumnChart.new
    simple_chart.message = Ambling::Data::Message.new "Test Broadcast"
    simple_chart.series.values << Ambling::Data::Value.new(10, :xid => 1)
    simple_chart.series << 20
    simple_chart.series.push Ambling::Data::Value.new(30, :xid => 3)
    
    graph = Ambling::Data::ColumnGraph.new
    graph.values << Ambling::Data::Value.new(100, :xid => 1)
    graph << 200
    graph << Ambling::Data::Value.new(300, :xid => 3)
    
    simple_chart.graphs << graph

    assert_xml_equal @simple_chart_xml, simple_chart.to_xml,
      "Expected |#{@simple_chart_xml}| but was |#{simple_chart.to_xml}|"
    
    advanced_chart = Ambling::Data::LineChart.new
    advanced_chart.message = Ambling::Data::Message.new "Advanced Broadcast", {:bg_color => '#CCCCCC'}
    
    advanced_chart.series << Ambling::Data::Value.new(1, :xid => 100, :bg_color => '#000000')
    advanced_chart.series << Ambling::Data::Value.new(2, :xid => 101, :bg_color => '#FFFFFF')
    
    advanced_chart.graphs << Ambling::Data::LineGraph.new([], :gid => "test_gid", :title => "test_title")
    advanced_chart.graphs.last << Ambling::Data::Value.new(1000, :xid => 1, :color => '#AAAAAA', :url => "http://yp.to")
    advanced_chart.graphs.last << Ambling::Data::Value.new(2000, :xid => 2, :color => '#BBBBBB', :start => 5)
    
    puts advanced_chart.to_xml
    
    assert_xml_equal @advanced_chart_xml, advanced_chart.to_xml,
      "Expected |#{@advanced_chart_xml}| but was |#{advanced_chart.to_xml}|"
    
  end
  
  def test_pie_to_xml
    simple_pie = Ambling::Data::Pie.new
    simple_pie.message = "Pie Broadcast"
    simple_pie << Ambling::Data::Slice.new(50, :title => "One Slice")
    simple_pie.slices << Ambling::Data::Slice.new(25, :title => "Two Slice", :url => "http://two.foo")
    
    assert_xml_equal @simple_pie_xml, simple_pie.to_xml,
      "Expected |#{@simple_pie_xml}| but was |#{simple_pie.to_xml}|"
  end
  
  def test_xy_to_xml
    simple_xy = Ambling::Data::XyChart.new
    simple_xy.graphs << Ambling::Data::XyGraph.new
    simple_xy.graphs.last << Ambling::Data::Point.new(:x => 1, :y => 10, :value => 100)
    simple_xy.graphs.last << Ambling::Data::Point.new(:x => 2, :y => 20, :value => 200)
    
    assert_xml_equal @simple_xy_xml, simple_xy.to_xml,
      "Expected |#{@simple_xy_xml}| but was |#{simple_xy.to_xml}|"
  end

end