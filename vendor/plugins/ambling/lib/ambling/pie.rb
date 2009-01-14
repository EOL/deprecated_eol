# Auto generated from XML file
require 'ambling/base'
module Ambling
  class Pie
    
    #
    # the top left corner has coordinates x = 0, y = 0                                                                
    #
    class Settings      
      include Base
      
      VALUES = [:data_type,:csv_separator,:skip_rows,:font,:text_size,:text_color,:decimals_separator,:thousands_separator,:digits_after_decimal,:reload_data_interval,:preloader_on_reload,:redraw,:add_time_stamp,:precision,:exclude_invisible,:pie,:animation,:data_labels,:group,:background,:balloon,:legend,:export_as_image,:error_messages,:strings,:labels]
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
      #  [0] (Number) how often data should be reloaded (time in seconds) 
      #
      attr_accessor :reload_data_interval
      
      #
      #  [false] (true / false) Whether to show preloaded when data or settings are reloaded 
      #
      attr_accessor :preloader_on_reload
      
      #
      #  [false] (true / false) if your chart's width or height is set in percents, and redraw is set to true, the chart will be redrawn then screen size changes 
      #
      attr_accessor :redraw
      
      #
      #  [false] (true / false) if true, a unique number will be added every time flash loads data. Mainly this feature is useful if you set reload _data_interval 
      #
      attr_accessor :add_time_stamp
      
      #
      #  [2] (Number) shows how many numbers should be shown after comma for calculated values (percents) 
      #
      attr_accessor :precision
      
      #
      #  [false] (true / false) whether to exclude invisible slices (where alpha=0) then calculating percent values or not 
      #
      attr_accessor :exclude_invisible
      
      #
      # 
      #
      attr_accessor :pie
      
      #
      # 
      #
      attr_accessor :animation
      
      #
      # 
      #
      attr_accessor :data_labels
      
      #
      # 
      #
      attr_accessor :group
      
      #
      #  BACKGROUND 
      #
      attr_accessor :background
      
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
      #
      #
      class Pie  
        include Base
        
        VALUES = [:x,:y,:radius,:inner_radius,:height,:angle,:outline_color,:outline_alpha,:base_color,:brightness_step,:colors,:link_target,:alpha]
        #
        #  [](Number) If left empty, will be positioned in the center 
        #
        attr_accessor :x
        
        #
        #  [](Number) If left empty, will be positioned in the center - 20px 
        #
        attr_accessor :y
        
        #
        #  [] (Number) If left empty, will be 25% of your chart smaller side 
        #
        attr_accessor :radius
        
        #
        #  [0] (Number) the radius of the hole (if you want to have donut, use > 0) 
        #
        attr_accessor :inner_radius
        
        #
        #  [0] (Number) pie height (for 3D effect) 
        #
        attr_accessor :height
        
        #
        #  [0] (0 - 90) lean angle (for 3D effect) 
        #
        attr_accessor :angle
        
        #
        #  [#FFFFFF] (hex color code) 
        #
        attr_accessor :outline_color
        
        #
        #  [0] (Number) 
        #
        attr_accessor :outline_alpha
        
        #
        #  [] (hex color code) color of first slice 
        #
        attr_accessor :base_color
        
        #
        #  [20] (-100 - 100) if base_color is used, every next slice is filled with lighter by brightnessStep % color. Use negative value if you want to get darker colors 
        #
        attr_accessor :brightness_step
        
        #
        #  [0xFF0F00,0xFF6600,0xFF9E01,0xFCD202,0xF8FF01,0xB0DE09,0x04D215,0x0D8ECF,0x0D52D1,0x2A0CD0,0x8A0CCF,0xCD0D74] (hex color codes separated by comas) 
        #
        attr_accessor :colors
        
        #
        #  [] (_blank, _top...) If pie slice has a link this is link target 
        #
        attr_accessor :link_target
        
        #
        #  [100] (0 - 100) slices alpha. You can set individual alphas for every slice in data file. If you set alpha to 0 the slice will be inactive for mouse events and data labels will be hidden. This allows you to make not full pies and donuts. 
        #
        attr_accessor :alpha
      end
      #
      #
      #
      class Animation  
        include Base
        
        VALUES = [:start_time,:start_effect,:start_radius,:start_alpha,:pull_out_on_click,:pull_out_time,:pull_out_effect,:pull_out_radius,:pull_out_only_one]
        #
        #  [0] (Number) fly-in time in seconds. Leave 0 to appear instantly 
        #
        attr_accessor :start_time
        
        #
        #  [bounce] (bounce, regular, strong) 
        #
        attr_accessor :start_effect
        
        #
        #  [] (Number) if left empty, will use pie.radius * 5 
        #
        attr_accessor :start_radius
        
        #
        #  [0] (Number) 
        #
        attr_accessor :start_alpha
        
        #
        #  [true] (true / false) whether to pull out slices when user clicks on them (or on legend entry) 
        #
        attr_accessor :pull_out_on_click
        
        #
        #  [0] (number) pull-out time (then user clicks on the slice) 
        #
        attr_accessor :pull_out_time
        
        #
        #  [bounce] (bounce, regular, strong) 
        #
        attr_accessor :pull_out_effect
        
        #
        #  [] (Number) how far pie slices should be pulled-out then user clicks on them (if left empty, uses 20% of pie radius) 
        #
        attr_accessor :pull_out_radius
        
        #
        #  [false] (true / false) if set to true, when you click on any slice, all other slices will be pushed in 
        #
        attr_accessor :pull_out_only_one
      end
      #
      #
      #
      class DataLabels  
        include Base
        
        VALUES = [:radius,:text_color,:text_size,:max_width,:show,:show_lines,:line_color,:line_alpha,:hide_labels_percent]
        #
        #  [30] (Number) distance of the labels from the pie. Use negative value to place labels on the pie 
        #
        attr_accessor :radius
        
        #
        #  [text_color] (hex color code) 
        #
        attr_accessor :text_color
        
        #
        #  [text_size] (Number) 
        #
        attr_accessor :text_size
        
        #
        #  [120] (Number) 
        #
        attr_accessor :max_width
        
        #
        #  [] ({value} {title} {percents}) You can format any data label: {value} - will be replaced with value and so on. You can add your own text or html code too. 
        #
        attr_accessor :show
        
        #
        #  [true] (true / false) whether to show lines from slices to data labels or not 
        #
        attr_accessor :show_lines
        
        #
        #  [#000000] (hex color code) 
        #
        attr_accessor :line_color
        
        #
        #  [15] (Number) 
        #
        attr_accessor :line_alpha
        
        #
        #  [0] data labels of slices less then skip_labels_percent% will be hidden (to avoid label overlapping if there are many small pie slices)
        #
        attr_accessor :hide_labels_percent
      end
      #
      #
      #
      class Group  
        include Base
        
        VALUES = [:percent,:color,:title,:url,:description,:pull_out]
        #
        #  [0] (Number) if the calculated percent value of a slice is less than specified here, and there are more than one such slices, they can be grouped to "The others" slice
        #
        attr_accessor :percent
        
        #
        #  [] (hex color code) color of "The others" slice 
        #
        attr_accessor :color
        
        #
        #  [Others] title of "The others" slice 
        #
        attr_accessor :title
        
        #
        #  [] url of "The others" slice 
        #
        attr_accessor :url
        
        #
        #  [] description of "The others" slice 
        #
        attr_accessor :description
        
        #
        #  [false] (true / false) whether to pull out the other slice or not 
        #
        attr_accessor :pull_out
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
        #  The chart will look for this file in path folder (path is set in HTML) 
        #
        attr_accessor :file
      end
      #
      # BALLOON 
      #
      class Balloon  
        include Base
        
        VALUES = [:enabled,:color,:alpha,:text_color,:text_size,:show]
        #
        #  [true] (true / false) 
        #
        attr_accessor :enabled
        
        #
        #  [] (hex color code) balloon background color. If empty, slightly darker then current slice color will be used 
        #
        attr_accessor :color
        
        #
        #  [80] (0 - 100) 
        #
        attr_accessor :alpha
        
        #
        #  [0xFFFFFF] (hex color code) 
        #
        attr_accessor :text_color
        
        #
        #  [text_size] (Number) 
        #
        attr_accessor :text_size
        
        #
        #  [] ({value} {title} {percents}) You can format any data label: {value} - will be replaced with value and so on. You can add your own text or html code too. 
        #
        attr_accessor :show
      end
      #
      # LEGEND 
      #
      class Legend  
        include Base
        
        VALUES = [:enabled,:x,:y,:width,:color,:max_columns,:alpha,:border_color,:border_alpha,:text_color,:text_size,:spacing,:margins,:reverse_order,:key,:values]
        #
        #  [true] (true / false) 
        #
        attr_accessor :enabled
        
        #
        #  [40] (Number) 
        #
        attr_accessor :x
        
        #
        #  [] (Number) if empty, will be below the pie 
        #
        attr_accessor :y
        
        #
        #  [] (Number) if empty, will be equal to flash width-80 
        #
        attr_accessor :width
        
        #
        #  [#FFFFFF] (hex color code) background color 
        #
        attr_accessor :color
        
        #
        #  [] (Number) the maximum number of columns in the legend 
        #
        attr_accessor :max_columns
        
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
        #  VALUES 
        #
        attr_accessor :values
        
        
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
        #
        # VALUES 
        #
        class Values  
          include Base
          
          VALUES = [:enabled,:width,:text]
          #
          #  [false] (true / false) whether to show values near legend entries or not 
          #
          attr_accessor :enabled
          
          #
          #  [] (Number) width of value text (use it if you want to align all values to the right, othervise leave empty) 
          #
          attr_accessor :width
          
          #
          #  [{percents}%] ({value} {percents}) 
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
        #  [] (filename) if you set filename here, context menu (then user right clicks on flash movie) "Export as image" will appear. This will allow user to export chart as an image. Collected image data will be posted to this file name (use ampie/export.php or ampie/export.aspx) 
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
    end
  end
end
