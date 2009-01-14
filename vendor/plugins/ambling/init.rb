require File.dirname(__FILE__) + '/lib/ambling'    
require File.dirname(__FILE__) + '/lib/ambling_helper'    

ActionView::Base.send(:include, Ambling::Helper)