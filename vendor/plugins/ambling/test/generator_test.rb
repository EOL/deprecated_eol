$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
require 'rubygems'
require 'ambling/utils'

class GeneratorTest < Test::Unit::TestCase
  
  def setup
    super
    begin
      Ambling::Column::Settings
    rescue
      g = Ambling::Utils::SettingsGenerator.new
      Object.module_eval g.generate(:column, File.read(File.join(File.dirname(__FILE__), "xmls", "simple.xml")))
    end
    
    @settings_hash = {:one => 111, :subsettings => {:type => 'atype', :width => '*'},
                      :graphs => {:graph => {:gid => 1, :type => 'column'}}}
    @settings = Ambling::Column::Settings.new @settings_hash
  end
  
  def test_settings_generator
    const = Ambling::Column::Settings
    assert_not_nil const
    top_attrs = const.const_get :VALUES
    assert_not_nil top_attrs
    assert_equal [:one, :blank, :subsettings, :graphs], top_attrs
    subattrs = const.const_get :ATTRIBUTES rescue nil
    assert_nil subattrs
    
    inst = const.new
    assert inst.respond_to?(:to_xml)
    assert inst.respond_to?(:build_xml)
    
    subconst = const.const_get :Subsettings
    assert_not_nil subconst
    subvalues = subconst.const_get :VALUES
    assert_not_nil subvalues
    assert_equal [:type, :width], subvalues
    subattrs = subconst.const_get :ATTRIBUTES rescue nil
    assert_nil subattrs
    
    subinst = subconst.new
    assert subinst.respond_to?(:to_xml)
    assert subinst.respond_to?(:build_xml)
    
    graphs = const.const_get :Graphs
    assert_not_nil graphs
    subvalues = graphs.const_get :VALUES
    assert_not_nil subvalues
    assert_equal [:graph], subvalues
    
    subattrs = graphs.const_get :ATTRIBUTES rescue nil
    assert_nil subattrs
    
    graph = graphs.const_get :Graph
    assert_not_nil graph
    subvalues = graph.const_get :VALUES
    assert_not_nil subvalues
    assert_equal [:type, :title], subvalues
    
    subattrs = graph.const_get :ATTRIBUTES
    assert_not_nil subattrs
    assert_equal [:gid], subattrs
    
    subinst = graph.new
    assert subinst.respond_to?(:to_xml)
    assert subinst.respond_to?(:build_xml)
    
    
  end
  
  def test_initialize
    assert_equal @settings_hash[:one], @settings.one
    assert_nil @settings.blank
    
    assert_equal @settings_hash[:subsettings][:type], @settings.subsettings.type
    assert_equal @settings_hash[:subsettings][:width], @settings.subsettings.width
    assert_equal @settings_hash[:graphs][:graph][:gid], @settings.graphs.graph.gid
    assert_equal @settings_hash[:graphs][:graph][:type], @settings.graphs.graph.type
    
    begin
      Ambling::Column::Settings.new(:bogus => 1)
      fail "Bogus variable initialization!"
    rescue NoMethodError
      # all is well
    end
    
    begin
      Ambling::Column::Settings.new(:one => 1, :bogus_subsettings => {:type => 1})
      fail "Bogus subsetting initialization!"
    rescue NameError
      # all is well
    end
  end
  
end