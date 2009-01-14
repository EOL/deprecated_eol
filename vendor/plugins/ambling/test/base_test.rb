$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'test/unit'
require 'ambling'
require 'test_helper'

class BaseTest < Test::Unit::TestCase
  include TestHelper
  
  def setup
    super
    @settings_hash = {:type => 'column', :column => {:type => 'atype', :width => '*'}}
    @settings = Ambling::Column::Settings.new @settings_hash
    
    @advanced_settings = read_and_strip_xml_file "advanced_settings.xml"
    
  end
  
  def test_to_xml
    assert_equal "<settings><type>column</type><column><type>atype</type><width>*</width></column></settings>",
      @settings.to_xml
    
    assert_equal "<column><type>column</type></column>",
      Ambling::Column::Settings::Column.new(:type => 'column').to_xml
      
    column_settings = Ambling::Column::Settings.new(
        :column => {
          :type => "stacked", :width => 90, :data_labels => "{total}"
        },
        :grid => {
          :category => {:alpha => 0}, :value => {:alpha => 10}
        },
        :values => {
          :category => {:enabled => false}
        },
        :plot_area => {
          :margins => {:left => 40, :top => 40, :right => 200, :bottom => 100}
        },
        :legend => {
          :enabled => true, :x => 150, :y => 100, :width => 80, :border_alpha => 100, :max_columns => 1, :text_size => 8
        },
        :labels => {
          :label => [
            {:x => 20, :y => 5, :text => "<![CDATA[<b>Bold Label</b>]]>",
              :text_size => 16, :text_color => '#A0A0A0'},
            {:x => 180, :y => 5, :text => "Plain"}
          ]
        }
    )
    assert_equal @advanced_settings, column_settings.to_xml
  end
end