# Auto generated from XML file
require 'ambling/base'
module Ambling
  class Xy
    
    #
    # value or explanation between () brackets shows the range or type of values you should use for this parameter 
    #
    class Settings      
      include Base
      
      VALUES = [:data_type,:csv_separator,:skip_rows,:font,:text_size,:text_color,:decimals_separator,:thousands_separator,:digits_after_decimal,:redraw,:reload_data_interval,:preloader_on_reload,:add_time_stamp,:depth,:angle,:link_target,:mask,:background,:plot_area,:grid,:values,:axes,:date_formats,:balloon,:legend,:export_as_image,:error_messages,:strings,:labels,:graphs]
      #
      #  [xml] (xml / csv) 
      #
      attr_accessor :data_type
      
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
      #  [,] (string) decimal separator. Note, that this is for displaying data only. Decimals in data xml file must be separated with a dot 
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
      #  [false] (true / false) if your chart's width or height is set in percents, and redraw is set to true, the chart will be redrawn then screen size changes 
      #
      attr_accessor :redraw
      
      #
      #  [0] (Number) how often data should be reloaded (time in seconds) 
      #
      attr_accessor :reload_data_interval
      
      #
      #  [false] (true / false) Whether to show preloaded when data or settings are reloaded 
      #
      attr_accessor :preloader_on_reload
      
      #
      #  [false] (true / false) if true, a unique number will be added every time flash loads data. Mainly this feature is useful if you set reload _data_interval 
      #
      attr_accessor :add_time_stamp
      
      #
      #  [0] (Number) the depth of chart and columns (for 3D effect) 
      #
      attr_accessor :depth
      
      #
      #  [30] (0 - 90) angle of chart area and columns (for 3D effect) 
      #
      attr_accessor :angle
      
      #
      #  [] (_blank, _top ...) 
      #
      attr_accessor :link_target
      
      #
      #  [true] if true, bubbles, data labels will be masked withing plot area 
      #
      attr_accessor :mask
      
      #
      #  BACKGROUND 
      #
      attr_accessor :background
      
      #
      #  PLOT AREA (the area between axes) 
      #
      attr_accessor :plot_area
      
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
      #  these settings are important only if your axis type is date or duration 
      #
      attr_accessor :date_formats
      
      #
      #  BALLOON 
      #
      attr_accessor :balloon
      
      #
      #  LEGEND 
      #
      attr_accessor :legend
      
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
        #  The chart will look for this file in amcolumn_path folder (amcolumn_path is set in HTML) 
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
      # GRID 
      #
      class Grid  
        include Base
        
        VALUES = [:x,:y]
        #
        #  x axis grid 
        #
        attr_accessor :x
        
        #
        #  y axis grid 
        #
        attr_accessor :y
        
        
        #
        # x axis grid 
        #
        class X  
          include Base
          
          VALUES = [:color,:alpha,:dashed,:dash_length,:approx_count]
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
        # y axis grid 
        #
        class Y  
          include Base
          
          VALUES = [:color,:alpha,:dashed,:dash_length,:approx_count]
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
        
        VALUES = [:x,:y]
        #
        #  x axis 
        #
        attr_accessor :x
        
        #
        #  y axis 
        #
        attr_accessor :y
        
        
        #
        # x axis 
        #
        class X  
          include Base
          
          VALUES = [:enabled,:type,:reverse,:min,:max,:strict_min_max,:frequency,:rotate,:skip_first,:skip_last,:color,:text_size,:unit,:unit_position,:integers_only,:inside]
          #
          #  [true] (true / false) 
          #
          attr_accessor :enabled
          
          #
          #  "date" means that your axis will display dates (you must specify date formats in <date_formats>) 
          #
          attr_accessor :type
          
          #
          #  [false] (true / false) whether to reverse this axis values or not. If set to true, values will start from biggest number and will end with a smallest number 
          #
          attr_accessor :reverse
          
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
          #  [0] (0 - 90) angle of rotation. If you want to rotate by degree from 1 to 89, you must have font.swf file in fonts folder 
          #
          attr_accessor :rotate
          
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
          #  [] (text) 
          #
          attr_accessor :unit
          
          #
          #  [right] (right / left) 
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
        # y axis 
        #
        class Y  
          include Base
          
          VALUES = [:enabled,:type,:reverse,:min,:max,:strict_min_max,:frequency,:rotate,:skip_first,:skip_last,:color,:text_size,:unit,:unit_position,:integers_only,:inside]
          #
          #  [true] (true / false) 
          #
          attr_accessor :enabled
          
          #
          #  "date" means that your axis will display dates (you must specify date formats in <date_formats>) 
          #
          attr_accessor :type
          
          #
          #  [false] (true / false) whether to reverse this axis values or not. If set to true, values will start from biggest number and will end with a smallest number 
          #
          attr_accessor :reverse
          
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
          #  [0] (0 - 90) angle of rotation. If you want to rotate by degree from 1 to 89, you must have font.swf file in fonts folder 
          #
          attr_accessor :rotate
          
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
          #  [] (text) 
          #
          attr_accessor :unit
          
          #
          #  [right] (right / left) 
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
        
        VALUES = [:x,:y]
        #
        #  x axis 
        #
        attr_accessor :x
        
        #
        #  y axis 
        #
        attr_accessor :y
        
        
        #
        # x axis 
        #
        class X  
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
        # y axis 
        #
        class Y  
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
      # these settings are important only if your axis type is date or duration 
      #
      class DateFormats  
        include Base
        
        VALUES = [:date_input,:duration_input,:axis_values,:balloon,:data_labels]
        #
        #  [YYYY-MM-DD hh:mm:ss] (YYYY, MM, DD, hh, mm, ss) date format of your data 
        #
        attr_accessor :date_input
        
        #
        #  [ss] (DD, mm, hh, ss) duration unit of your data (this is important only if your axis type is "duration") 
        #
        attr_accessor :duration_input
        
        #
        #  when axis type is "date", you must specify date formats for different intervals. "first" describes date format of the first grid line, "regular" - of all other grid lines 
        #
        attr_accessor :axis_values
        
        #
        #  [month DD, YYYY] balloon date format 
        #
        attr_accessor :balloon
        
        #
        #  [month DD, YYYY] data labels date format 
        #
        attr_accessor :data_labels
        
        
        #
        # when axis type is "date", you must specify date formats for different intervals. "first" describes date format of the first grid line, "regular" - of all other grid lines 
        #
        class AxisValues  
          include Base
          
          VALUES = [:ss,:mm,:hh,:DD,:MM,:YYYY]
          #
          #  [first="month DD, YYYY" regular="hh:mm:ss"] date formats when interval is second 
          #
          attr_accessor :ss
          
          #
          #  [first="month DD, YYYY" regular="hh:mm"] date formats when interval is minute 
          #
          attr_accessor :mm
          
          #
          #  [first="month DD, YYYY" regular="hh:mm"] date formats when interval is hour 
          #
          attr_accessor :hh
          
          #
          #  [first="month DD, YYYY" regular="month DD"] date formats when interval is day 
          #
          attr_accessor :DD
          
          #
          #  [first="month, YYYY" regular="month"] date formats when interval is month 
          #
          attr_accessor :MM
          
          #
          #  [first="YYYY" regular="YYYY"] date formats when interval is year 
          #
          attr_accessor :YYYY
        end
      end
      #
      # BALLOON 
      #
      class Balloon  
        include Base
        
        VALUES = [:enabled,:color,:alpha,:text_color,:text_size,:max_width]
        #
        #  [true] (true / false) 
        #
        attr_accessor :enabled
        
        #
        #  [] (hex color code) balloon background color. If empty, slightly darker then current column color will be used 
        #
        attr_accessor :color
        
        #
        #  [100] (0 - 100) 
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
        
        #
        #  [220] (Number) 
        #
        attr_accessor :max_width
      end
      #
      # LEGEND 
      #
      class Legend  
        include Base
        
        VALUES = [:enabled,:x,:y,:width,:max_columns,:color,:alpha,:border_color,:border_alpha,:text_color,:text_size,:spacing,:margins,:reverse_order,:key]
        #
        #  [true] (true / false) 
        #
        attr_accessor :enabled
        
        #
        #  [] (Number) if empty, will be equal to left margin 
        #
        attr_accessor :x
        
        #
        #  [] (Number) if empty, will be below plot area 
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
        #  [false] (true / false) whether to sort legend entries in a reverse order 
        #
        attr_accessor :reverse_order
        
        #
        #  KEY (the color box near every legend entry) 
        #
        attr_accessor :key
        
        
        #
        # KEY (the color box near every legend entry) 
        #
        class Key  
          include Base
          
          VALUES = [:size,:border_color]
          #
          #  [16] (Number) key size
          #
          attr_accessor :size
          
          #
          #  [] (hex color code) leave empty if you don't want to have border 
          #
          attr_accessor :border_color
        end
      end
      #
      # export_as_image feature works only on a web server 
      #
      class ExportAsImage  
        include Base
        
        VALUES = [:file,:target,:x,:y,:color,:alpha,:text_color,:text_size]
        #
        #  [] (filename) if you set filename here, context menu (then user right clicks on flash movie) "Export as image" will appear. This will allow user to export chart as an image. Collected image data will be posted to this file name (use amxy/export.php or amxy/export.aspx) 
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
        
        VALUES = [:no_data,:export_as_image,:collecting_data,:ss,:mm,:hh,:DD,:months]
        #
        #  [No data for selected period] (text) if data is missing, this message will be displayed 
        #
        attr_accessor :no_data
        
        #
        #  [Export as image] (text) text for right click menu 
        #
        attr_accessor :export_as_image
        
        #
        #  [Collecting data] (text) this text is displayed while exporting chart to an image 
        #
        attr_accessor :collecting_data
        
        #
        #  [] unit of seconds 
        #
        attr_accessor :ss
        
        #
        #  [:] unit of minutes 
        #
        attr_accessor :mm
        
        #
        #  [:] unit of hours 
        #
        attr_accessor :hh
        
        #
        #  [d ] unit of days 
        #
        attr_accessor :DD
        
        #
        # 
        #
        attr_accessor :months
        
        
        #
        #
        #
        class Months  
          include Base
          
          VALUES = [:month1,:month2,:month3,:month4,:month5,:month6,:month7,:month8,:month9,:month10,:month11,:month12]
          #
          # 
          #
          attr_accessor :month1
          
          #
          # 
          #
          attr_accessor :month2
          
          #
          # 
          #
          attr_accessor :month3
          
          #
          # 
          #
          attr_accessor :month4
          
          #
          # 
          #
          attr_accessor :month5
          
          #
          # 
          #
          attr_accessor :month6
          
          #
          # 
          #
          attr_accessor :month7
          
          #
          # 
          #
          attr_accessor :month8
          
          #
          # 
          #
          attr_accessor :month9
          
          #
          # 
          #
          attr_accessor :month10
          
          #
          # 
          #
          attr_accessor :month11
          
          #
          # 
          #
          attr_accessor :month12
        end
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
          #  [false] (true, false) 
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
          
          VALUES = [:title,:color,:alpha,:width,:data_labels,:balloon_text,:bullet_max_size,:bullet_min_size,:bullet,:bullet_size,:bullet_color,:bullet_alpha,:visible_in_legend]
          ATTRIBUTES = [:gid]
          #
          #  [] (graph title) 
          #
          attr_accessor :title
          
          #
          #  [] (hex color code)  
          #
          attr_accessor :color
          
          #
          #  [100] (0 - 100) line alpha. WIll not affect bullets. Set to 0 if you want the line to be invisible 
          #
          attr_accessor :alpha
          
          #
          #  [0] (Number) line width 
          #
          attr_accessor :width
          
          #
          #  [] ({title} {value} {description} {x} {y} {percents}) You can format any data label: {title} will be replaced with real title, {value} - with value and so on. You can add your own text or html code too. 
          #
          attr_accessor :data_labels
          
          #
          #  [] ({title} {value} {description} {x} {y} {percents}) You can format any data label: {title} will be replaced with real title, {value} - with value and so on. You can add your own text or html code too. You can also use {title}, {value} and other tags in description. 
          #
          attr_accessor :balloon_text
          
          #
          #  [50] maximum size of a bullet (balloon) The bullet with the highest value will be equal to this size 
          #
          attr_accessor :bullet_max_size
          
          #
          #  [0] minimum size of a bullet (balloon) 
          #
          attr_accessor :bullet_min_size
          
          #
          #  [] (square, round, square_outlined, round_outlined, filename.swf) can be used predefined bullets or loaded custom bullets. Leave empty if you don't want to have bullets at all. Outlined bullets use plot area color for outline color 
          #
          attr_accessor :bullet
          
          #
          #  [] (Number) bullet size. This param is only used if your values are not set in data file 
          #
          attr_accessor :bullet_size
          
          #
          #  [] (hex color code) bullet color. If not defined, graph color is used 
          #
          attr_accessor :bullet_color
          
          #
          #  [100] (Number) 
          #
          attr_accessor :bullet_alpha
          
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
