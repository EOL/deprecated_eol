module OptiFlag
  module Flagset
    module Help
      class Bundle 
        attr_accessor :help,:extended_help,:banner;
      end
      StandardHelpBundle = Bundle.new
      StandardHelpBundle.banner = proc  do |render_on|     
        render_on.printf("Help for commands:\n")
      end
      StandardHelpBundle.help  = proc do |render_on,flag|
          render_on.printf("  #{ flag.the_dash_symbol }%-10s (#{ flag.the_is_required ? 'Required' : 'Optional' }, takes #{flag.the_arity} argument#{ (flag.the_arity==1) ? '' : 's' })\n",  flag.flag)        
          render_on.printf("                  #{ flag.the_description}\n") if flag.the_description        
      end
      StandardHelpBundle.extended_help = proc do |render_on,flag|
        render_on.puts "----------------"
        desc = ""
        desc <<  <<-EOF if flag.the_description
    Description:        #{ flag.the_description  }
         EOF
        desc << <<-EOF
           Flag:        #{ flag.the_dash_symbol }#{ flag.flag  } (#{ flag.the_is_required ? 'Required' : 'Optional' }, takes #{flag.the_arity} argument#{ (flag.the_arity==1) ? '' : 's' }) 
              EOF
        desc <<  <<-EOF if flag.the_long_form
      Long Form:        #{ flag.the_long_dash_symbol }#{ flag.the_long_form  }
         EOF
        desc << <<-EOF if flag.the_alternate_forms.length > 0
Alternate Flags:        #{ flag.the_alternate_forms.collect{|x| "#{ flag.the_dash_symbol}#{ x}" }.join(', ')  }              
         EOF
        render_on.puts desc
      end
      MAN_HELP = proc do |render_on,flag|
        render_on.puts <<-EOHELP
       #{ flag.the_dash_symbol }#{flag.flag }, #{ flag.the_long_dash_symbol }#{ flag.the_long_form}
              #{ flag.the_description }

EOHELP
      end
    end
  end
end

