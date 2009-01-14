# Generates chart object tag with given url to fetch the xml data.
# See README for more information

module Ambling #:nodoc
  module Helper #:nodoc
    class AmblingHelperError < StandardError #:nodoc
    end
    
    CHART_PATH = "/amcharts" unless defined? CHART_PATH
                        
    # Generates chart object tag with given url to fetch the xml data.
    # See Ambling for examples
    # Chart Options:
    # * <tt>:width</tt> - The width of the chart
    # * <tt>:height</tt> - The height of the chart
    # * <tt>:swf_path</tt> - The path that contains the chart.swf.  Defaults to /amcharts
    # * <tt>:flash_version</tt> - Supported flash version.  Defaults to 8
    # * <tt>:background_color</tt> - The chart background color.  Defaults to '#FFFFFF'
    # * <tt>:preloader_color</tt> - The color of the preloading text.  Defaults to '#000000'
    # * <tt>:express_install</tt> - Use the swfobject express install if the browser does not have flash installed. Defaults to true
    # * <tt>:id</tt> - The id of the DOM element that will be replaced
    # * <tt>:settings_file</tt> - The path to the xml settings file (could be url)
    # * <tt>:chart_settings</tt> - Inline xml settings.  Use one of settings_file and chart_settings
    # * <tt>:additional_chart_settings</tt> - More inline xml settings.
    # * <tt>:data_file</tt> - The path to the xml data file (could be url)
    # * <tt>:chart_data</tt> - Inline xml data.  Use one of data_file and chart_data
    def ambling_chart(chart_type, chart_options = {}, &block)
      options = { :width              => "400",
                  :height             => "300",
                  :swf_path           => CHART_PATH,
                  :flash_version      => "8",
                  :background_color   => "#FFFFFF",
                  :preloader_color    => "#000000",
                  :express_install    => true,
                  :id                 => "ambling_chart"
                }.merge!(chart_options)
      script = "var so = new SWFObject('#{options[:swf_path]}/am#{chart_type}.swf', " +
                                      "'#{options[:id]}', '#{options[:width]}', '#{options[:height]}', " +
                                      "'#{options[:flash_version]}', '#{options[:background_color]}');"
      script << "so.addVariable('path', '#{options[:swf_path]}/');"
      script << "so.useExpressInstall('#{options[:swf_path]}/expressinstall.swf');" if options[:express_install]
      
      script << add_variable(options, :settings_file, true)
      script << add_variable(options, :chart_settings)
      script << add_variable(options, :additional_chart_settings)
      
      script << add_variable(options, :data_file, true)
      script << add_variable(options, :chart_data)
      
      script << add_variable(options, :preloader_color)
      script << "so.write('#{options[:id]}');"
      html = yield
      content_tag('div', html, :id => options[:id]) + javascript_tag(script)
    end
    
    private

    # Add variable to swfobject
    def add_variable(options, key, escape=false)
      return "" unless options[key]
      stresc = options[key].gsub('"', "%22")
      val = escape ? "escape('#{stresc}')" : "'#{stresc}'"
      "so.addVariable('#{key}', #{val});"
    end
  end
end
