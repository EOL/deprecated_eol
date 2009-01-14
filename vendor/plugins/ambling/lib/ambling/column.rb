# Auto generated from XML file
require 'ambling/base'
module Ambling
  class Column
    
    #
    # value or explanation between () brackets shows the range or type of values you should use for this parameter 
    #
    class Settings      
      include Base
      
      VALUES = [:type,:data_type,:csv_separator,:skip_rows,:font,:text_size,:text_color,:decimals_separator,:thousands_separator,:digits_after_decimal,:redraw,:reload_data_interval,:preloader_on_reload,:add_time_stamp,:precision,:depth,:angle,:column,:line,:background,:plot_area,:grid,:values,:axes,:balloon,:legend,:export_as_image,:error_messages,:strings,:labels,:graphs]
      #
      #  [column] (column / bar) 
      #
      attr_accessor :type
      
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
      #  this function is beta, be careful. Legend, buttons labels will not be repositioned if you set your x and y values for these objects 
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
      #  [2] (Number) shows how many numbers should be shown after comma for calculated values (percents) 
      #
      attr_accessor :precision
      
      #
      #  [0] (Number) the depth of chart and columns (for 3D effect) 
      #
      attr_accessor :depth
      
      #
      #  [30] (0 - 90) angle of chart area and columns (for 3D effect) 
      #
      attr_accessor :angle
      
      #
      # 
      #
      attr_accessor :column
      
      #
      #  Here are general settings for "line" graph type. You can set most of these settings for individual lines in graph settings below 
      #
      attr_accessor :line
      
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
      #
      #
      class Column  
        include Base
        
        VALUES = [:type,:width,:spacing,:grow_time,:grow_effect,:alpha,:border_color,:border_alpha,:data_labels,:data_labels_text_color,:data_labels_text_size,:data_labels_position,:balloon_text,:link_target,:gradient,:bullet_offset]
        #
        #  [clustered] (stacked, 100% stacked) 
        #
        attr_accessor :type
        
        #
        #  [80] (0 - 100) width of column (in percents)  
        #
        attr_accessor :width
        
        #
        #  [5] (Number) space between columns of one category axis value, in pixels. Negative values can be used. 
        #
        attr_accessor :spacing
        
        #
        #  [0] (Number) grow time in seconds. Leave 0 to appear instantly 
        #
        attr_accessor :grow_time
        
        #
        #  [elastic] (elastic, regular, strong) 
        #
        attr_accessor :grow_effect
        
        #
        #  [100] (Number) alpha of all columns 
        #
        attr_accessor :alpha
        
        #
        #  [#FFFFFF] (hex color code) 
        #
        attr_accessor :border_color
        
        #
        #  [0] (Number) 
        #
        attr_accessor :border_alpha
        
        #
        #  [] ({title} {value} {series} {percents} {start} {difference} {total}) You can format any data label: {title} will be replaced with real title, {value} - with value and so on. You can add your own text or html code too. 
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
        #  if you set "above" for column chart, the data label will be displayed inside column, rotated  by 90 degrees 
        #
        attr_accessor :data_labels_position
        
        #
        #  [] ({title} {value} {series} {percents} {start} {difference} {total}) You can format any data label: {title} will be replaced with real title, {value} - with value and so on. You can add your own text or html code too. 
        #
        attr_accessor :balloon_text
        
        #
        #  [] (_blank, _top ...) 
        #
        attr_accessor :link_target
        
        #
        #  [vertical] (horizontal / vertical) Direction of column gradient. Gradient colors are defined in graph settings below. 
        #
        attr_accessor :gradient
        
        #
        #  [0] (Number) distance from column / bar to the bullet 
        #
        attr_accessor :bullet_offset
      end
      #
      # Here are general settings for "line" graph type. You can set most of these settings for individual lines in graph settings below 
      #
      class Line  
        include Base
        
        VALUES = [:connect,:width,:alpha,:fill_alpha,:bullet,:bullet_size,:data_labels,:data_labels_text_color,:data_labels_text_size,:balloon_text,:link_target]
        #
        #  [false] (true / false) whether to connect points if data is missing 
        #
        attr_accessor :connect
        
        #
        #  [2] (Number) line width 
        #
        attr_accessor :width
        
        #
        #  [100] (Number) line alpha 
        #
        attr_accessor :alpha
        
        #
        #  [0] (Number) fill alpha 
        #
        attr_accessor :fill_alpha
        
        #
        #  [] (square, round, square_outlined, round_outlined, filename.swf) can be used predefined bullets or loaded custom bullets. Leave empty if you don't want to have bullets at all. Outlined bullets use plot area color for outline color 
        #
        attr_accessor :bullet
        
        #
        #  [8] (Number) bullet size 
        #
        attr_accessor :bullet_size
        
        #
        #  [] ({title} {value} {series} {percents} {start} {difference} {total}) You can format any data label: {title} will be replaced with real title, {value} - with value and so on. You can add your own text or html code too. 
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
        #  [] use the same formatting rules as for data labels 
        #
        attr_accessor :balloon_text
        
        #
        #  [] (_blank, _top ...) 
        #
        attr_accessor :link_target
      end
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
        
        VALUES = [:category,:value]
        #
        #  category axis grid 
        #
        attr_accessor :category
        
        #
        #  value axis grid 
        #
        attr_accessor :value
        
        
        #
        # category axis grid 
        #
        class Category  
          include Base
          
          VALUES = [:color,:alpha,:dashed,:dash_length]
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
        end
        #
        # value axis grid 
        #
        class Value  
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
        
        VALUES = [:category,:value]
        #
        #  category axis 
        #
        attr_accessor :category
        
        #
        #  value axis 
        #
        attr_accessor :value
        
        
        #
        # category axis 
        #
        class Category  
          include Base
          
          VALUES = [:enabled,:frequency,:rotate,:color,:text_size,:inside]
          #
          #  [true] (true / false) 
          #
          attr_accessor :enabled
          
          #
          #  [1] (Number) how often values should be placed 
          #
          attr_accessor :frequency
          
          #
          #  [0] (0 - 90) angle of rotation. If you want to rotate by degree from 1 to 89, you must have font.swf file in fonts folder 
          #
          attr_accessor :rotate
          
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
        # value axis 
        #
        class Value  
          include Base
          
          VALUES = [:enabled,:reverse,:min,:max,:strict_min_max,:frequency,:rotate,:skip_first,:skip_last,:color,:text_size,:unit,:unit_position,:integers_only,:inside]
          #
          #  [true] (true / false) 
          #
          attr_accessor :enabled
          
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
        
        VALUES = [:category,:value]
        #
        #  category axis 
        #
        attr_accessor :category
        
        #
        #  value axis 
        #
        attr_accessor :value
        
        
        #
        # category axis 
        #
        class Category  
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
        # value axis 
        #
        class Value  
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
      # BALLOON 
      #
      class Balloon  
        include Base
        
        VALUES = [:enabled,:color,:alpha,:text_color,:text_size]
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
        #  [] (filename) if you set filename here, context menu (then user right clicks on flash movie) "Export as image" will appear. This will allow user to export chart as an image. Collected image data will be posted to this file name (use amcolumn/export.php or amcolumn/export.aspx) 
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
        
        VALUES = [:no_data,:export_as_image,:collecting_data]
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
          
          VALUES = [:type,:title,:color,:alpha,:data_labels,:gradient_fill_colors,:balloon_color,:balloon_alpha,:balloon_text_color,:balloon_text,:fill_alpha,:width,:bullet,:bullet_size,:bullet_color,:visible_in_legend]
          ATTRIBUTES = [:gid]
          #
          # 
          #
          attr_accessor :type
          
          #
          #  [] (graph title) 
          #
          attr_accessor :title
          
          #
          #  [] (hex color code)  
          #
          attr_accessor :color
          
          #
          #  [column.alpha (line.alpha)] (0 - 100) 
          #
          attr_accessor :alpha
          
          #
          #  [column.data_labels (line.data_labels)] ({title} {value} {series} {percents} {start} {difference} {total}) You can format any data label: {title} will be replaced with real title, {value} - with value and so on. You can add your own text or html code too. 
          #
          attr_accessor :data_labels
          
          #
          #  [] (hex color codes separated by comas) columns can be filled with gradients. Set any number of colors here. Note, that the legend key will be filled with color value, not with gradient. 
          #
          attr_accessor :gradient_fill_colors
          
          #
          #  [balloon.color] (hex color code) leave empty to use the same color as graph 
          #
          attr_accessor :balloon_color
          
          #
          #  [balloon.alpha] (0 - 100) 
          #
          attr_accessor :balloon_alpha
          
          #
          #  [balloon.text_color] (hex color code) 
          #
          attr_accessor :balloon_text_color
          
          #
          #  [column(line).balloon.text] ({title} {value} {series} {description} {percents}) You can format any balloon text: {title} will be replaced with real title, {value} - with value and so on. You can add your own text or html code too. 
          #
          attr_accessor :balloon_text
          
          #
          #  [0] (0 - 100) fill alpha (use it if you want to have area chart) 
          #
          attr_accessor :fill_alpha
          
          #
          #  [2] (Number) line width 
          #
          attr_accessor :width
          
          #
          #  [line.bullet] (round, square, round_outlined, square_outlined, filename) 
          #
          attr_accessor :bullet
          
          #
          #  [line.bullet_size] (Number) bullet size 
          #
          attr_accessor :bullet_size
          
          #
          #  [] (hex color code) bullet color. If not defined, line color is used 
          #
          attr_accessor :bullet_color
          
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
