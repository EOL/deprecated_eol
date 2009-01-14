# Auto generated from XML file
require 'ambling/base'
module Ambling
  class Line
    
    #
    # value or explanation between () brackets shows the range or type of values you should use for this parameter 
    #
    class Settings      
      include Base
      
      VALUES = [:data_type,:type,:csv_separator,:skip_rows,:font,:text_size,:text_color,:decimals_separator,:thousands_separator,:digits_after_decimal,:redraw,:reload_data_interval,:preloader_on_reload,:add_time_stamp,:precision,:connect,:hide_bullets_count,:link_target,:start_on_axis,:background,:plot_area,:scroller,:grid,:values,:axes,:indicator,:legend,:zoom_out_button,:help,:export_as_image,:error_messages,:strings,:labels,:graphs]
      #
      #  [xml] (xml / csv) 
      #
      attr_accessor :data_type
      
      #
      #  [line] (line, stacked, 100% stacked) 
      #
      attr_accessor :type
      
      #
      #  [;] (string) csv file data separator (you need it only if you are using csv file for your data) 
      #
      attr_accessor :csv_separator
      
      #
      #  [0] (Number) if you are using csv data type, you can set the number of rows which should be skipped here 
      #
      attr_accessor :skip_rows
      
      #
      #  [Arial] (font name) use device fonts, such as Arial, Times New Roman, Tahoma, Verdana... 
      #
      attr_accessor :font
      
      #
      #  [11] (Number) text size of all texts. Every text size can be set individually in the settings below 
      #
      attr_accessor :text_size
      
      #
      #  [#000000] (hex color code) main text color. Every text color can be set individually in the settings below
      #
      attr_accessor :text_color
      
      #
      #  [,] (string) decimal separator. Note, that this is for displaying data only. Decimals in data xml file must be separated with dot 
      #
      attr_accessor :decimals_separator
      
      #
      #  [ ] (string) thousand separator 
      #
      attr_accessor :thousands_separator
      
      #
      #  [] (Number) if your value has less digits after decimal then is set here, zeroes will be added 
      #
      attr_accessor :digits_after_decimal
      
      #
      #  Legend, buttons labels will not be repositioned if you set your x and y values for these objects 
      #
      attr_accessor :redraw
      
      #
      #  [0] (Number) how often data should be reloaded (time in seconds) If you are using this feature I strongly recommend to turn off zoom function (set <zoomable>false</zoomable>) 
      #
      attr_accessor :reload_data_interval
      
      #
      #  [false] (true / false) Whether to show preloaded when data or settings are reloaded 
      #
      attr_accessor :preloader_on_reload
      
      #
      #  [false] (true / false) if true, a unique number will be added every time flash loads data. Mainly this feature is useful if you set reload _data_interval >0 
      #
      attr_accessor :add_time_stamp
      
      #
      #  [2] (Number) shows how many numbers should be shown after comma for calculated values (percents, used only in stacked charts) 
      #
      attr_accessor :precision
      
      #
      #  [false] (true / false) whether to connect points if y data is missing 
      #
      attr_accessor :connect
      
      #
      #  [] (Number) if there are more then hideBulletsCount points on the screen, bullets can be hidden, to avoid mess. Leave empty, or 0 to show bullets all the time. This rule doesn't influence if custom bullet is defined near y value, in data file 
      #
      attr_accessor :hide_bullets_count
      
      #
      #  [] (_blank, _top ...) 
      #
      attr_accessor :link_target
      
      #
      #  [true] (true / false) if set to false, graph is moved 1/2 of one series interval from Y axis 
      #
      attr_accessor :start_on_axis
      
      #
      #  BACKGROUND 
      #
      attr_accessor :background
      
      #
      #  PLOT AREA (the area between axes) 
      #
      attr_accessor :plot_area
      
      #
      # 
      #
      attr_accessor :scroller
      
      #
      #  GRID 
      #
      attr_accessor :grid
      
      #
      #  VALUES 
      #
      attr_accessor :values
      
      #
      #  axes 
      #
      attr_accessor :axes
      
      #
      #  INDICATOR 
      #
      attr_accessor :indicator
      
      #
      #  LEGEND 
      #
      attr_accessor :legend
      
      #
      # 
      #
      attr_accessor :zoom_out_button
      
      #
      #  HELP button and balloon 
      #
      attr_accessor :help
      
      #
      #  export_as_image feature works only on a web server 
      #
      attr_accessor :export_as_image
      
      #
      #  "error_messages" settings will be applied for all error messages except the one which is showed if settings file wasn't found 
      #
      attr_accessor :error_messages
      
      #
      # 
      #
      attr_accessor :strings
      
      #
      #  labels can also be added in data xml file, using exactly the same structure like it is here 
      #
      attr_accessor :labels
      
      #
      #  if graph settings are defined both here and in data file, the ones from data file are used 
      #
      attr_accessor :graphs
      
      
      #
      # BACKGROUND 
      #
      class Background  
        include Base
        
        VALUES = [:color,:alpha,:border_color,:border_alpha,:file]
        #
        #  [#FFFFFF] (hex color code) 
        #
        attr_accessor :color
        
        #
        #  [0] (0 - 100) use 0 if you are using custom swf or jpg for background 
        #
        attr_accessor :alpha
        
        #
        #  [#000000] (hex color code) 
        #
        attr_accessor :border_color
        
        #
        #  [0] (0 - 100) 
        #
        attr_accessor :border_alpha
        
        #
        #  The chart will look for this file in amline_path folder (amline_path is set in HTML) 
        #
        attr_accessor :file
      end
      #
      # PLOT AREA (the area between axes) 
      #
      class PlotArea  
        include Base
        
        VALUES = [:color,:alpha,:border_color,:border_alpha,:margins]
        #
        #  [#FFFFFF](hex color code) 
        #
        attr_accessor :color
        
        #
        #  [0] (0 - 100) if you want it to be different than background color, use bigger than 0 value 
        #
        attr_accessor :alpha
        
        #
        #  [#000000] (hex color code) 
        #
        attr_accessor :border_color
        
        #
        #  [0] (0 - 100) 
        #
        attr_accessor :border_alpha
        
        #
        #  plot area margins 
        #
        attr_accessor :margins
        
        
        #
        # plot area margins 
        #
        class Margins  
          include Base
          
          VALUES = [:left,:top,:right,:bottom]
          #
          #  [60](Number) 
          #
          attr_accessor :left
          
          #
          #  [60](Number) 
          #
          attr_accessor :top
          
          #
          #  [60](Number) 
          #
          attr_accessor :right
          
          #
          #  [80](Number) 
          #
          attr_accessor :bottom
        end
      end
      #
      #
      #
      class Scroller  
        include Base
        
        VALUES = [:enabled,:y,:color,:alpha,:bg_color,:bg_alpha,:height]
        #
        #  [true] (true / false) whether to show scroller when chart is zoomed or not 
        #
        attr_accessor :enabled
        
        #
        #  [] (Number) Y position of scroller. If not set here, will be displayed above plot area 
        #
        attr_accessor :y
        
        #
        #  [#DADADA] (hex color code) scrollbar color 
        #
        attr_accessor :color
        
        #
        #  [100] (Number) scrollbar alpha 
        #
        attr_accessor :alpha
        
        #
        #  [#F0F0F0] (hex color code) scroller background color 
        #
        attr_accessor :bg_color
        
        #
        #  [100] (Number) scroller background alpha 
        #
        attr_accessor :bg_alpha
        
        #
        #  [10] (Number) scroller height 
        #
        attr_accessor :height
      end
      #
      # GRID 
      #
      class Grid  
        include Base
        
        VALUES = [:x,:y_left,:y_right]
        #
        #  vertical grid 
        #
        attr_accessor :x
        
        #
        #  horizontal grid, Y left axis. Visible only if there is at least one graph assigned to left axis 
        #
        attr_accessor :y_left
        
        #
        #  horizontal grid, Y right axis. Visible only if there is at least one graph assigned to right axis 
        #
        attr_accessor :y_right
        
        
        #
        # vertical grid 
        #
        class X  
          include Base
          
          VALUES = [:enabled,:color,:alpha,:dashed,:dash_length,:approx_count]
          #
          #  [true] (true / false) 
          #
          attr_accessor :enabled
          
          #
          #  [#000000] (hex color code) 
          #
          attr_accessor :color
          
          #
          #  [15] (0 - 100) 
          #
          attr_accessor :alpha
          
          #
          #  [false](true / false) 
          #
          attr_accessor :dashed
          
          #
          #  [5] (Number) 
          #
          attr_accessor :dash_length
          
          #
          #  [4] (Number) approximate number of gridlines 
          #
          attr_accessor :approx_count
        end
        #
        # horizontal grid, Y left axis. Visible only if there is at least one graph assigned to left axis 
        #
        class YLeft  
          include Base
          
          VALUES = [:enabled,:color,:alpha,:dashed,:dash_length,:approx_count]
          #
          #  [true] (true / false) 
          #
          attr_accessor :enabled
          
          #
          #  [#000000] (hex color code) 
          #
          attr_accessor :color
          
          #
          #  [15] (0 - 100) 
          #
          attr_accessor :alpha
          
          #
          #  [false] (true / false) 
          #
          attr_accessor :dashed
          
          #
          #  [5] (Number) 
          #
          attr_accessor :dash_length
          
          #
          #  [10] (Number) approximate number of gridlines 
          #
          attr_accessor :approx_count
        end
        #
        # horizontal grid, Y right axis. Visible only if there is at least one graph assigned to right axis 
        #
        class YRight  
          include Base
          
          VALUES = [:enabled,:color,:alpha,:dashed,:dash_length,:approx_count]
          #
          #  [true] (true / false) 
          #
          attr_accessor :enabled
          
          #
          #  [#000000] (hex color code) 
          #
          attr_accessor :color
          
          #
          #  [15] (0 - 100) 
          #
          attr_accessor :alpha
          
          #
          #  [false] (true / false) 
          #
          attr_accessor :dashed
          
          #
          #  [5] (Number) 
          #
          attr_accessor :dash_length
          
          #
          #  [10] (Number) approximate number of gridlines 
          #
          attr_accessor :approx_count
        end
      end
      #
      # VALUES 
      #
      class Values  
        include Base
        
        VALUES = [:x,:y_left,:y_right]
        #
        #  x axis 
        #
        attr_accessor :x
        
        #
        #  y left axis 
        #
        attr_accessor :y_left
        
        #
        #  y right axis 
        #
        attr_accessor :y_right
        
        
        #
        # x axis 
        #
        class X  
          include Base
          
          VALUES = [:enabled,:rotate,:frequency,:skip_first,:skip_last,:color,:text_size,:inside]
          #
          #  [true] (true / false) 
          #
          attr_accessor :enabled
          
          #
          #  [0] (0 - 90) angle of rotation. If you want to rotate by degree from 1 to 89, you must have font.swf file in fonts folder 
          #
          attr_accessor :rotate
          
          #
          #  [1] (Number) how often values should be placed, 1 - near every gridline, 2 - near every second gridline... 
          #
          attr_accessor :frequency
          
          #
          #  [false] (true / false) to skip or not first value 
          #
          attr_accessor :skip_first
          
          #
          #  [false] (true / false) to skip or not last value 
          #
          attr_accessor :skip_last
          
          #
          #  [text_color] (hex color code) 
          #
          attr_accessor :color
          
          #
          #  [text_size] (Number) 
          #
          attr_accessor :text_size
          
          #
          #  [false] (true / false) if set to true, axis values will be displayed inside plot area. This setting will not work for values rotated by 1-89 degrees (0 and 90 only) 
          #
          attr_accessor :inside
        end
        #
        # y left axis 
        #
        class YLeft  
          include Base
          
          VALUES = [:enabled,:reverse,:rotate,:min,:max,:strict_min_max,:frequency,:skip_first,:skip_last,:color,:text_size,:unit,:unit_position,:integers_only,:inside]
          #
          #  [true] (true / false) 
          #
          attr_accessor :enabled
          
          #
          #  [false] (true / false) whether to reverse this axis values or not. If set to true, values will start from biggest number and will end with a smallest number 
          #
          attr_accessor :reverse
          
          #
          #  [0] (0 - 90) angle of rotation. If you want to rotate by degree from 1 to 89, you must have font.swf file in fonts folder 
          #
          attr_accessor :rotate
          
          #
          #  [] (Number) minimum value of this axis. If empty, this value will be calculated automatically. 
          #
          attr_accessor :min
          
          #
          #  [] (Number) maximum value of this axis. If empty, this value will be calculated automatically 
          #
          attr_accessor :max
          
          #
          #  [false] (true / false) by default, if your values are bigger then defined max (or smaller then defined min), max and min is changed so that all the chart would fit to chart area. If you don't want this, set this option to true. 
          #
          attr_accessor :strict_min_max
          
          #
          #  [1] (Number) how often values should be placed, 1 - near every gridline, 2 - near every second gridline... 
          #
          attr_accessor :frequency
          
          #
          #  [true] (true / false) to skip or not first value 
          #
          attr_accessor :skip_first
          
          #
          #  [false] (true / false) to skip or not last value 
          #
          attr_accessor :skip_last
          
          #
          #  [text_color] (hex color code) 
          #
          attr_accessor :color
          
          #
          #  [text_size] (Number) 
          #
          attr_accessor :text_size
          
          #
          #  [] (text) unit which will be added to values on y axis
          #
          attr_accessor :unit
          
          #
          #  [right] (left / right) 
          #
          attr_accessor :unit_position
          
          #
          #  [false] (true / false) if set to true, values with decimals will be omitted 
          #
          attr_accessor :integers_only
          
          #
          #  [false] (true / false) if set to true, axis values will be displayed inside plot area. This setting will not work for values rotated by 1-89 degrees (0 and 90 only) 
          #
          attr_accessor :inside
        end
        #
        # y right axis 
        #
        class YRight  
          include Base
          
          VALUES = [:enabled,:reverse,:rotate,:min,:max,:strict_min_max,:frequency,:skip_first,:skip_last,:color,:text_size,:unit,:unit_position,:integers_only,:inside]
          #
          #  [true] (true / false) 
          #
          attr_accessor :enabled
          
          #
          #  [false] (true / false) whether to reverse this axis values or not. If set to true, values will start from biggest number and will end with a smallest number 
          #
          attr_accessor :reverse
          
          #
          #  [0] (0 - 90) angle of rotation. If you want to rotate by degree from 1 to 89, you must have font.swf file in fonts folder 
          #
          attr_accessor :rotate
          
          #
          #  [] (Number) minimum value of this axis. If empty, this value will be calculated automatically 
          #
          attr_accessor :min
          
          #
          #  [] (Number) maximum value of this axis. If empty, this value will be calculated automatically 
          #
          attr_accessor :max
          
          #
          #  [false] (true / false) by default, if your values are bigger then defined max (or smaller then defined min), max and min is changed so that all the chart would fit to chart area. If you don't want this, set this option to true. 
          #
          attr_accessor :strict_min_max
          
          #
          #  [1] (Number) how often values should be placed, 1 - near every gridline, 2 - near every second gridline... 
          #
          attr_accessor :frequency
          
          #
          #  [true] (true / false) to skip or not first value 
          #
          attr_accessor :skip_first
          
          #
          #  [false] (true / false) to skip or not last value 
          #
          attr_accessor :skip_last
          
          #
          #  [text_color] (hex color code) 
          #
          attr_accessor :color
          
          #
          #  [text_size] (Number) 
          #
          attr_accessor :text_size
          
          #
          #  [] (text) unit which will be added to values on y axis
          #
          attr_accessor :unit
          
          #
          #  [right] (left / right) 
          #
          attr_accessor :unit_position
          
          #
          #  [false] (true / false) if set to true, values with decimals will be omitted 
          #
          attr_accessor :integers_only
          
          #
          #  [false] (true / false) if set to true, axis values will be displayed inside plot area. This setting will not work for values rotated by 1-89 degrees (0 and 90 only) 
          #
          attr_accessor :inside
        end
      end
      #
      # axes 
      #
      class Axes  
        include Base
        
        VALUES = [:x,:y_left,:y_right]
        #
        #  X axis 
        #
        attr_accessor :x
        
        #
        #  Y left axis, visible only if at least one graph is assigned to this axis 
        #
        attr_accessor :y_left
        
        #
        #  Y right axis, visible only if at least one graph is assigned to this axis 
        #
        attr_accessor :y_right
        
        
        #
        # X axis 
        #
        class X  
          include Base
          
          VALUES = [:color,:alpha,:width,:tick_length]
          #
          #  [#000000] (hex color code) 
          #
          attr_accessor :color
          
          #
          #  [100] (0 - 100) 
          #
          attr_accessor :alpha
          
          #
          #  [2] (Number) line width, 0 for hairline 
          #
          attr_accessor :width
          
          #
          #  [7] (Number) 
          #
          attr_accessor :tick_length
        end
        #
        # Y left axis, visible only if at least one graph is assigned to this axis 
        #
        class YLeft  
          include Base
          
          VALUES = [:color,:alpha,:width,:tick_length,:logarithmic]
          #
          #  [#000000] (hex color code) 
          #
          attr_accessor :color
          
          #
          #  [100] (0 - 100) 
          #
          attr_accessor :alpha
          
          #
          #  [2] (Number) line width, 0 for hairline 
          #
          attr_accessor :width
          
          #
          #  [7] (Number) 
          #
          attr_accessor :tick_length
          
          #
          #  [false] (true / false) If set to true, this axis will use logarithmic scale instead of linear 
          #
          attr_accessor :logarithmic
        end
        #
        # Y right axis, visible only if at least one graph is assigned to this axis 
        #
        class YRight  
          include Base
          
          VALUES = [:color,:alpha,:width,:tick_length,:logarithmic]
          #
          #  [#000000] (hex color code) 
          #
          attr_accessor :color
          
          #
          #  [100] (0 - 100) 
          #
          attr_accessor :alpha
          
          #
          #  [2] (Number) line width, 0 for hairline 
          #
          attr_accessor :width
          
          #
          #  [7] (Number) 
          #
          attr_accessor :tick_length
          
          #
          #  [false] (true / false) If set to true, this axis will use logarithmic scale instead of linear 
          #
          attr_accessor :logarithmic
        end
      end
      #
      # INDICATOR 
      #
      class Indicator  
        include Base
        
        VALUES = [:enabled,:zoomable,:color,:line_alpha,:selection_color,:selection_alpha,:x_balloon_enabled,:x_balloon_text_color,:y_balloon_text_size,:y_balloon_on_off,:one_y_balloon]
        #
        #  [true] (true / false) 
        #
        attr_accessor :enabled
        
        #
        #  [true] (true / false) 
        #
        attr_accessor :zoomable
        
        #
        #  [#BBBB00] (hex color code) line and x balloon background color 
        #
        attr_accessor :color
        
        #
        #  [100] (0 - 100) 
        #
        attr_accessor :line_alpha
        
        #
        #  [#BBBB00] (hex color code) 
        #
        attr_accessor :selection_color
        
        #
        #  [25] (0 - 100) 
        #
        attr_accessor :selection_alpha
        
        #
        #  [true] (true / false) 
        #
        attr_accessor :x_balloon_enabled
        
        #
        #  [text_color] (hex color code) 
        #
        attr_accessor :x_balloon_text_color
        
        #
        #  [text_size] (Number) 
        #
        attr_accessor :y_balloon_text_size
        
        #
        #  [true] (true / false) whether it is possible to turn on/off y balloon by clicking on graphs or legend. Works only if indicator is enabled 
        #
        attr_accessor :y_balloon_on_off
        
        #
        #  [false] (true / false) if you set it to true, only one y balloon will be visible at a time 
        #
        attr_accessor :one_y_balloon
      end
      #
      # LEGEND 
      #
      class Legend  
        include Base
        
        VALUES = [:enabled,:x,:y,:width,:max_columns,:color,:alpha,:border_color,:border_alpha,:text_color,:text_color_hover,:text_size,:spacing,:margins,:graph_on_off,:reverse_order,:key,:values]
        #
        #  [true] (true / false) 
        #
        attr_accessor :enabled
        
        #
        #  [] (Number) if empty, will be equal to left margin 
        #
        attr_accessor :x
        
        #
        #  [] (Number) if empty, will be 20px below x axis values 
        #
        attr_accessor :y
        
        #
        #  [] (Number) if empty, will be equal to plot area width 
        #
        attr_accessor :width
        
        #
        #  [] (Number) the maximum number of columns in the legend 
        #
        attr_accessor :max_columns
        
        #
        #  [#FFFFFF] (hex color code) background color 
        #
        attr_accessor :color
        
        #
        #  [0] (0 - 100) background alpha 
        #
        attr_accessor :alpha
        
        #
        #  [#000000] (hex color code) border color 
        #
        attr_accessor :border_color
        
        #
        #  [0] (0 - 100) border alpha 
        #
        attr_accessor :border_alpha
        
        #
        #  [text_color] (hex color code) 
        #
        attr_accessor :text_color
        
        #
        #  [#BBBB00] (hex color code) 
        #
        attr_accessor :text_color_hover
        
        #
        #  [text_size] (Number) 
        #
        attr_accessor :text_size
        
        #
        #  [10] (Number) vertical and horizontal gap between legend entries 
        #
        attr_accessor :spacing
        
        #
        #  [0] (Number) legend margins (space between legend border and legend entries, recommended to use only if legend border is visible or background color is different from chart area background color) 
        #
        attr_accessor :margins
        
        #
        #  [true] (true / false) if true, color box gains "checkbox" function - it is possible to make graphs visible/invisible by clicking on this checkbox 
        #
        attr_accessor :graph_on_off
        
        #
        #  [false] (true / false) whether to sort legend entries in a reverse order 
        #
        attr_accessor :reverse_order
        
        #
        #  KEY (the color box near every legend entry) 
        #
        attr_accessor :key
        
        #
        #  VALUES 
        #
        attr_accessor :values
        
        
        #
        # KEY (the color box near every legend entry) 
        #
        class Key  
          include Base
          
          VALUES = [:size,:border_color,:key_mark_color]
          #
          #  [16] (Number) key size
          #
          attr_accessor :size
          
          #
          #  [] (hex color code) leave empty if you don't want to have border
          #
          attr_accessor :border_color
          
          #
          #  [#FFFFFF] (hex color code) key tick mark color 
          #
          attr_accessor :key_mark_color
        end
        #
        # VALUES 
        #
        class Values  
          include Base
          
          VALUES = [:enabled,:width,:align,:text]
          #
          #  [false] (true / false) whether to show values near legend entries or not 
          #
          attr_accessor :enabled
          
          #
          #  [80] (Number) width of text field for value 
          #
          attr_accessor :width
          
          #
          #  [right] (right / left) 
          #
          attr_accessor :align
          
          #
          #  [{value}] ({title} {value} {series} {description} {percents}) You can format any text: {value} will be replaced with value, {description} - with description and so on. You can add your own text or html code too. 
          #
          attr_accessor :text
        end
      end
      #
      #
      #
      class ZoomOutButton  
        include Base
        
        VALUES = [:x,:y,:color,:alpha,:text_color,:text_color_hover,:text_size,:text]
        #
        #  [] (Number) x position of zoom out button, if not defined, will be aligned to right of plot area 
        #
        attr_accessor :x
        
        #
        #  [] (Number) y position of zoom out button, if not defined, will be aligned to top of plot area 
        #
        attr_accessor :y
        
        #
        #  [#BBBB00] (hex color code) background color 
        #
        attr_accessor :color
        
        #
        #  [0] (0 - 100) background alpha 
        #
        attr_accessor :alpha
        
        #
        #  [text_color] (hex color code) button text and magnifying glass icon color 
        #
        attr_accessor :text_color
        
        #
        #  [#BBBB00] (hex color code) button text and magnifying glass icon roll over color 
        #
        attr_accessor :text_color_hover
        
        #
        #  [text_size] (Number) button text size 
        #
        attr_accessor :text_size
        
        #
        #  [Show all] (text) 
        #
        attr_accessor :text
      end
      #
      # HELP button and balloon 
      #
      class Help  
        include Base
        
        VALUES = [:button,:balloon]
        #
        #  help button is only visible if balloon text is defined 
        #
        attr_accessor :button
        
        #
        #  help balloon 
        #
        attr_accessor :balloon
        
        
        #
        # help button is only visible if balloon text is defined 
        #
        class Button  
          include Base
          
          VALUES = [:x,:y,:color,:alpha,:text_color,:text_color_hover,:text_size,:text]
          #
          #  [] (Number) x position of help button, if not defined, will be aligned to right of chart area 
          #
          attr_accessor :x
          
          #
          #  [] (Number) y position of help button, if not defined, will be aligned to top of chart area 
          #
          attr_accessor :y
          
          #
          #  [#000000] (hex color code) background color 
          #
          attr_accessor :color
          
          #
          #  [100] (0 - 100) background alpha 
          #
          attr_accessor :alpha
          
          #
          #  [#FFFFFF] (hex color code) button text color 
          #
          attr_accessor :text_color
          
          #
          #  [#BBBB00](hex color code) button text roll over color 
          #
          attr_accessor :text_color_hover
          
          #
          #  [] (Number) button text size 
          #
          attr_accessor :text_size
          
          #
          #  [?] (text) 
          #
          attr_accessor :text
        end
        #
        # help balloon 
        #
        class Balloon  
          include Base
          
          VALUES = [:color,:alpha,:width,:text_color,:text_size,:text]
          #
          #  [#000000] (hex color code) background color 
          #
          attr_accessor :color
          
          #
          #  [100] (0 - 100) background alpha 
          #
          attr_accessor :alpha
          
          #
          #  [300] (Number) 
          #
          attr_accessor :width
          
          #
          #  [#FFFFFF] (hex color code) button text color 
          #
          attr_accessor :text_color
          
          #
          #  [] (Number) button text size 
          #
          attr_accessor :text_size
          
          #
          #  [] (text) some html tags may be used (supports <b>, <i>, <u>, <font>, <br/>. Enter text between []: <![CDATA[your <b>bold</b> and <i>italic</i> text]]>
          #
          attr_accessor :text
        end
      end
      #
      # export_as_image feature works only on a web server 
      #
      class ExportAsImage  
        include Base
        
        VALUES = [:file,:target,:x,:y,:color,:alpha,:text_color,:text_size]
        #
        #  [] (filename) if you set filename here, context menu (then user right clicks on flash movie) "Export as image" will appear. This will allow user to export chart as an image. Collected image data will be posted to this file name (use amline/export.php or amline/export.aspx) 
        #
        attr_accessor :file
        
        #
        #  [] (_blank, _top ...) target of a window in which export file must be called 
        #
        attr_accessor :target
        
        #
        #  [0] (Number) x position of "Collecting data" text 
        #
        attr_accessor :x
        
        #
        #  [] (Number) y position of "Collecting data" text. If not set, will be aligned to the bottom of flash movie 
        #
        attr_accessor :y
        
        #
        #  [#BBBB00] (hex color code) background color of "Collecting data" text 
        #
        attr_accessor :color
        
        #
        #  [0] (0 - 100) background alpha 
        #
        attr_accessor :alpha
        
        #
        #  [text_color] (hex color code) 
        #
        attr_accessor :text_color
        
        #
        #  [text_size] (Number) 
        #
        attr_accessor :text_size
      end
      #
      # "error_messages" settings will be applied for all error messages except the one which is showed if settings file wasn't found 
      #
      class ErrorMessages  
        include Base
        
        VALUES = [:enabled,:x,:y,:color,:alpha,:text_color,:text_size]
        #
        #  [true] (true / false) 
        #
        attr_accessor :enabled
        
        #
        #  [] (Number) x position of error message. If not set, will be aligned to the center 
        #
        attr_accessor :x
        
        #
        #  [] (Number) y position of error message. If not set, will be aligned to the center 
        #
        attr_accessor :y
        
        #
        #  [#BBBB00] (hex color code) background color of error message 
        #
        attr_accessor :color
        
        #
        #  [100] (0 - 100) background alpha 
        #
        attr_accessor :alpha
        
        #
        #  [#FFFFFF] (hex color code) 
        #
        attr_accessor :text_color
        
        #
        #  [text_size] (Number) 
        #
        attr_accessor :text_size
      end
      #
      #
      #
      class Strings  
        include Base
        
        VALUES = [:no_data,:export_as_image,:error_in_data_file,:collecting_data,:wrong_zoom_value]
        #
        #  [No data for selected period] (text) if data for selected period is missing, this message will be displayed 
        #
        attr_accessor :no_data
        
        #
        #  [Export as image] (text) text for right click menu 
        #
        attr_accessor :export_as_image
        
        #
        #  [Error in data file] (text) this text is displayed if there is an error in data file or there is no data in file. "There is no data" means that there should actually be at least one space in data file. If data file will be completly empty, it will display "error loading file" text 
        #
        attr_accessor :error_in_data_file
        
        #
        #  [Collecting data] (text) this text is displayed while exporting chart to an image 
        #
        attr_accessor :collecting_data
        
        #
        #  [Incorrect values] (text) this text is displayed if you set zoom through JavaScript and entered from or to value was not find between series 
        #
        attr_accessor :wrong_zoom_value
      end
      #
      # labels can also be added in data xml file, using exactly the same structure like it is here 
      #
      class Labels  
        include Base
        
        VALUES = [:label]
        #
        # 
        #
        attr_accessor :label
        
        
        #
        #
        #
        class Label  
          include Base
          
          VALUES = [:x,:y,:rotate,:width,:align,:text_color,:text_size,:text]
          #
          #  [0] (Number) 
          #
          attr_accessor :x
          
          #
          #  [0] (Number) 
          #
          attr_accessor :y
          
          #
          #  [false] (true / false) 
          #
          attr_accessor :rotate
          
          #
          #  [] (Number) if empty, will stretch from left to right untill label fits 
          #
          attr_accessor :width
          
          #
          #  [left] (left / center / right) 
          #
          attr_accessor :align
          
          #
          #  [text_color] (hex color code) button text color 
          #
          attr_accessor :text_color
          
          #
          #  [text_size](Number) button text size 
          #
          attr_accessor :text_size
          
          #
          #  [] (text) html tags may be used (supports <b>, <i>, <u>, <font>, <a href="">, <br/>. Enter text between []: <![CDATA[your <b>bold</b> and <i>italic</i> text]]>
          #
          attr_accessor :text
        end
      end
      #
      # if graph settings are defined both here and in data file, the ones from data file are used 
      #
      class Graphs  
        include Base
        
        VALUES = [:graph]
        #
        #  if you are using XML data file, graph "gid" must match graph "gid" in data file 
        #
        attr_accessor :graph
        
        
        #
        # if you are using XML data file, graph "gid" must match graph "gid" in data file 
        #
        class Graph  
          include Base
          
          VALUES = [:axis,:title,:color,:color_hover,:line_alpha,:line_width,:fill_alpha,:fill_color,:balloon_color,:balloon_alpha,:balloon_text_color,:bullet,:bullet_size,:bullet_color,:bullet_alpha,:hidden,:selected,:balloon_text,:data_labels,:data_labels_text_color,:data_labels_text_size,:data_labels_position,:vertical_lines,:visible_in_legend]
          ATTRIBUTES = [:gid]
          #
          #  [left] (left/ right) indicates which y axis should be used 
          #
          attr_accessor :axis
          
          #
          #  [] (graph title) 
          #
          attr_accessor :title
          
          #
          #  [] (hex color code) if not defined, uses colors from this array: #FF0000, #0000FF, #00FF00, #FF9900, #CC00CC, #00CCCC, #33FF00, #990000, #000066 
          #
          attr_accessor :color
          
          #
          #  [#BBBB00] (hex color code) 
          #
          attr_accessor :color_hover
          
          #
          #  [100] (0 - 100) 
          #
          attr_accessor :line_alpha
          
          #
          #  [0] (Number) 0 for hairline 
          #
          attr_accessor :line_width
          
          #
          #  [0] (0 - 100) if you want the chart to be area chart, use bigger than 0 value 
          #
          attr_accessor :fill_alpha
          
          #
          #  [grpah.color] (hex color code) 
          #
          attr_accessor :fill_color
          
          #
          #  [graph color] (hex color code) leave empty to use the same color as graph 
          #
          attr_accessor :balloon_color
          
          #
          #  [100] (0 - 100) 
          #
          attr_accessor :balloon_alpha
          
          #
          #  [#FFFFFF] (hex color code) 
          #
          attr_accessor :balloon_text_color
          
          #
          #  The chart will look for this file in amline_path folder (amline_path is set in HTML) 
          #
          attr_accessor :bullet
          
          #
          #  [6](Number) affects only predefined (square and round) bullets, does not change size of custom loaded bullets 
          #
          attr_accessor :bullet_size
          
          #
          #  [graph color] (hex color code) affects only predefined (square and round) bullets, does not change color of custom loaded bullets. Leave empty to use the same color as graph  
          #
          attr_accessor :bullet_color
          
          #
          #  [graph alpha] (hex color code) Leave empty to use the same alpha as graph 
          #
          attr_accessor :bullet_alpha
          
          #
          #  [false] (true / false) vill not be visible until you check corresponding checkbox in the legend 
          #
          attr_accessor :hidden
          
          #
          #  [true] (true / false) if true, balloon indicating value will be visible then roll over plot area 
          #
          attr_accessor :selected
          
          #
          #  [<b>{value}</b><br>{description}] ({title} {value} {series} {description} {percents}) You can format any balloon text: {title} will be replaced with real title, {value} - with value and so on. You can add your own text or html code too. 
          #
          attr_accessor :balloon_text
          
          #
          #  to avoid overlapping, data labels, the same as bullets are not visible if there are more then hide_bullets_count data points on plot area. 
          #
          attr_accessor :data_labels
          
          #
          #  [text_color] (hex color code) 
          #
          attr_accessor :data_labels_text_color
          
          #
          #  [text_size] (Number) 
          #
          attr_accessor :data_labels_text_size
          
          #
          #  [above] (below / above) 
          #
          attr_accessor :data_labels_position
          
          #
          #  [false] (true / false) whether to draw vertical lines or not. If you want to show vertical lines only (without the graph, set line_alpha to 0 
          #
          attr_accessor :vertical_lines
          
          #
          #  [true] (true / false) whether to show legend entry for this graph or not 
          #
          attr_accessor :visible_in_legend
          
          #
          # xml attribute
          #
          attr_accessor :gid
        end
      end    
    end
  end
end
