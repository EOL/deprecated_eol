# == OptiFlag "Command Line DSL" Parser
# Please see:
# http://optiflag.rubyforge.org
# for useful examples and discussion.
#
# Author:: Daniel O. Eklund
# Copyright:: Copyright (c) 2006 Daniel O. Eklund. All rights reserved.
# License:: Ruby license.
module OptiFlag
  VERSION = "0.7" 
end

load 'optiflag-help.rb'
load 'optiflag-parse.rb'

module OptiFlag
  module Flagset
    @dash_symbol = "-"
    attr_reader :dash_symbol
    module_function :dash_symbol
    # method called by 'send' using a hash of
    # values, the key being the name
    # of the method (this method) and the
    # value being the parameter to be passed
    # to the method.  Therefore,
    #   module Example extend OptiFlagSet(:flag_symbol => "/")
    # is invoking this method 'flag_symbol' and passing
    # the value "/" as the parameter.
    # See the RDoc for the *method* 'OptiFlag::Flagset()'
    # in the OptiFlag module,
    # *not* the module OptiFlag::Flagset which it resembles.
    #
    # This method, when invoked using the above expression
    # changes the default flag symbol from "-" to whatever 
    # is passed in.  Thus, if we wanted to simulate
    # the MSDos flags, we would use:
    #   module Example extend OptiFlagSet(:flag_symbol => "/")
    # which would then parse a command line looking like:
    #   /h /renew /username daniel /password fluffy
    def self.flag_symbol(val)
      @dash_symbol = val
    end
    def self.increment_order_counter()
      @counter ||= 0
      @counter = @counter + 1
      return @counter -1
    end
  end
end

module OptiFlag
  module Flagset
    # The class *EachFlag* is the template for each flag
    # instantiated by a <i>flag set declaration</i>.
    # One EachFlag is instantiated for each <i>flag 
    # declaration</i>.  For example, the following <i>flag-set
    # declaration</i>:
    #
    #     module Example extend OptiFlagSet
    #       flag "dir"
    #       optional_flag "log"
    #       flag "username"
    #       flag "password"
    #     end 
    #
    # will instantiate four EachFlag instances.
    #
    # The <i>flag declarations</i> are methods on the OptiFlag::Flagset
    # module that actually instantiate each
    # one of these EachFlag instances. They are listed in the
    # RDoc for the OptiFlag::Flagset sub-module and are labeled
    # as top-level flag-declarers.
    #
    # An EachFlag object has many methods belonging to 
    # different categories of usage (though nothing enforced 
    # by the language or the code itself).
    # 
    # == Clause Level Modifiers
    # These are methods that are used by the API _user_ of the
    # OptiFlag suite,(i.e. a programmer of other Ruby code but not
    # the OptiFlag code itself).  These methods are used *within*
    # a <i>flag declaration</i>. For example, in the following code:
    #
    #     module Example extend OptiFlagSet
    #       flag "dir" do 
    #         alternate_forms "directory","D","d"
    #         description "The Appliction Directory"
    #       end
    #       optional_flag "log" do
    #         description "The directory in which to find the log files"
    #         long_form "logging-directory" # long form is keyed after the '--' symbol
    #       end
    #     end 
    #
    # There will be two EachFlag instances instantiated.  For the
    # first EachFlag instance, the one named "dir", two of these
    # <i>clause-level modifiers</i> are invoked *on* the Eachflag instance
    # by the OptiFlag *user*.  These clause-level modifiers modify the
    # expected behavior of each
    #
    # == List (clause API) of <i>clause level modifiers</i>
    # * 'description' -- the description of the 
    # * 'required' -- indicates whether this flag is required
    # 
    # == Internal Implementation Notes
    # This RDoc section is of concern only to implementors
    # of OptiFlag.  If you are using OptiFlag in your 
    # application, chances are this section is of little use to you.
    #
    # === 'the' members.
    # Because OptiFlag seeks to provide a nice DSL to the user,
    # many of the names of the clause-level modifiers are also
    # useful names for methods which could access the internal
    # field.
    # 
    # So, we have a problem.  For instance, in the following
    # code:
    #     module Example extend OptiFlagSet
    #       flag "username", :description => "Database username."  # alternate form
    #    
    #       and_process!
    #     end 
    # the method 'description' has been written to modify the EachClass
    # instance appropriately.  But now, if you are accessing this
    # EachClass instance in some other part of the OptiFlag internals
    # (as, for instance, the help functionality would), then the use
    # of the attr syntax would clash with this method.
    #   attr_accessor :description
    #   # this meta-code would generate both the 
    #   # getter and the setter, where the getter method
    #   #    def description()
    #   #       return @desciption
    #   #    end
    #   # would conflict with the description method we
    #   # have provided for the user
    # The solution to this problem is to leave the standard (useful)
    # method names for the <i>clause level modifiers</i> of the 
    # EachFlag instance and introduce another *consistent* name
    # for <b>the actual</b> internal field.
    # For a while, these internal fields and their attr's were
    # named the_actual_description etc.  But this proved to
    # be a mouthful.  Thereafter, the consistent naming scheme was
    # to place 'the_' in front of the field.
    #
    # Therefore, for most of the data based <i>clause level modifiers</i>
    # (live 'description' which saves the description the user
    # has provided), there is provided a parallel 'the_description'
    # accessor ( or reader or writer, depending on the needs).
    #
    # In summary, 'description' is a public API (for use by
    # users of the OptiFlag suite) and 'the_description' is a
    # a package-protected API.
    class EachFlag
      attr_reader :name, :flag, :order_added,:validation_error,:enclosing_module,:default_used
      # the 'the' values.. the actual means by which to access the values
      # set by the clause-level modifiers.
      attr_reader :the_pretranslate,:the_posttranslate,
          :the_posttranslate_all,:the_pretranslate_all,:the_description,:the_long_dash_symbol,:the_dash_symbol,
          :the_arity,:the_long_form,:the_alternate_forms,:the_validation_rules,
          :the_is_required
      attr_writer :the_form_that_is_actually_used
      attr_accessor :value,:for_help,:for_extended_help,:proxied_bound_method
      def initialize(name,flag,enclosing_module)
        # these next two lines are a highly complicated hack needed to make
        # the use of two module definitions in one file, one with a flag_symbol
        # and one without.. See tc_change_symbols.rb for the two tests that used to
        # cause the problem... also see the changes as part of the definition of 
        # OptiFlag.Flagset()....    -- D.O.E 5/30/06
        # Search for 'def OptiFlag.Flagset(hash)' in this 
        singleton_class_of_enclosing_module =  class << enclosing_module; self; end;
        x = singleton_class_of_enclosing_module.included_modules.select do |x| 
             (x.to_s =~ /OptiF/) or  (x.to_s =~ /#<Modu/)  
        end[0]
        # the following batch of code is pure initialization
        @the_compresses,@enclosing_module = false,enclosing_module
        @validation_error,@the_validation_rules = [],[]
        @order_added = OptiFlag::Flagset::increment_order_counter()
        @name,@flag,@the_long_form = name,flag,flag
        @the_dash_symbol, @the_arity, @the_alternate_forms,
             @the_is_required, @the_long_dash_symbol = x.dash_symbol, 1, [], true, "--"
#        puts "#{ @order_added } --- #{ @name }"
      end
      # translate() is a clause-level flag-modifier.
      # It can be used in the following form:
      # 
      def translate(position=0,&theblock)
        pretranslate(position,&theblock)
      end
      # clause-level flag-modifier
      def translate_all(&theblock)
        pretranslate_all(&theblock)
      end
      # clause-level flag-modifier
      def pretranslate(position=0,&theblock)
        @the_pretranslate ||= []
        @the_pretranslate[position] = theblock
      end
      # clause-level flag-modifier
      def posttranslate(position=0,&theblock)
        @the_posttranslate ||= []
        @the_posttranslate[position] = theblock
      end
      # clause-level flag-modifier
      def pretranslate_all(&theblock)
        @the_pretranslate_all = theblock
      end
      # clause-level flag-modifier
      def posttranslate_all(&theblock)
        @the_posttranslate_all = theblock
      end
      # clause-level flag-modifier
      def is_required(yes_or_no)
        @the_is_required = yes_or_no
      end   
      # clause-level flag-modifier
      def value_matches(desc_regexp_pair,arg_position=0)
        if desc_regexp_pair.class == Regexp
          desc_regexp_pair = 
            ["This value does not match the pattern: #{ desc_regexp_pair.source }",
             desc_regexp_pair]
        end
        validates_against do |flag,errors|
          value = [flag.value] if value.class != Array
          desc,regexp = desc_regexp_pair
          if ! value[arg_position].match regexp
             problem = "For the flag: '#{ flag.as_string_basic }' the value you gave was '#{ value[arg_position] }'."
             problem << "\n #{ desc }"
            errors << problem
          end
        end
      end
      # clause-level flag-modifier
      def value_in_set(array_of_acceptable_values,arg_position=0)
        # refactored to use validates_against
        validates_against do |flag,errors|
          value = [flag.value] if value.class != Array
          something_matches = 
            array_of_acceptable_values.select{|x| x.to_s == value[arg_position] }
          if something_matches.length == 0
            problem = <<-PROBLEMO
For the flag: '#{ flag.as_string_basic }' the value you gave was '#{ value[arg_position] }'.
But the value must be one of the following: [#{ array_of_acceptable_values.join(', ') }]
            PROBLEMO
            errors << problem
          end 
        end
      end 
      # <b>Clause-level modifier.</b>
      # The user of this construct will pass a block that accepts two arguments:  
      # * the flag (of class EachFlag) and 
      # * an errors array.
      # If the user wants to indicate that a validation error has occurred
      # (and that further processing should stop) he/she needs to add a 
      # string of the problem to the errrors array.<br/>
      # The following (silly) example validates that the username is 'daniel'.
      # If it's not, the code adds to the errors array, and OptiFlag will
      # indicate a validation error.
      #   flag "username"
      #       description "The username"
      #       validates_against do |flag,errors|
      #         if flag.value != "daniel"
      #           errors << "You are NOT DANIEL!"
      #         end
      #       end
      #   end
      def validates_against(&theblock)
        @the_validation_rules ||= [] 
        @the_validation_rules << theblock
      end
      # clause-level flag-modifier      
      def required
        is_required(true)
      end
      # clause-level flag-modifier
      def optional
        is_required(false)
      end
      # * Clause-level flag-modifier.
      # * Synonym for 'no_args'.
      # * Takes no arguments (for itself).
      # * Indicates that the flag takes no arguments. (i.e.
      #   the flag has zero arity).
      # * Sample usage (embedded within a <i>flag set declaration</i>):
      #     flag "log" do
      #       no_arg
      #     end
      def no_arg
        no_args
      end
      # Clause-level flag-modifier.
      def no_args
        arity 0
      end
      # clause-level flag-modifier
      def one_arg
        arity 1
      end
      # clause-level flag-modifier      
      def two_args
        arity 2
      end
      # clause-level flag-modifier
      def alternate_forms(*args)
        @the_alternate_forms = args[0] if args[0].class == Array
        @the_alternate_forms =  @the_alternate_forms + args if args[0].class != Array

      end
      # clause-level flag-modifier
      def long_form(form)
        @the_long_form = form
      end

      # clause-level flag-modifier
      def default(default_value)
        @default_used = true
        @value = default_value
      end

      # clause-level flag-modifier
      def arity(num)
        @the_arity = num
      end
      # clause-level flag-modifier
      def dash_symbol(symb)
        @the_dash_symbol = symb
      end
      # clause-level flag-modifier
      def long_dash_symbol(symb)
        @the_long_dash_symbol = symb
      end
      # clause-level flag-modifier
      def description(desc)
        @the_description = desc
      end
      # clause-level flag-modifier
      def compresses(val=true)
        @the_compresses = val
      end
      def as_string_basic
        "#{ self.the_dash_symbol }#{ self.flag }"
      end
      def as_alternate_forms
        ret = @the_alternate_forms.collect do |x|
          "#{ self.the_dash_symbol }#{ x }"
        end
      end
      def as_string_extended
        "#{ self.the_long_dash_symbol  }#{self.the_long_form  }"
      end
      def as_the_form_that_is_actually_used
        @the_form_that_is_actually_used
      end
      def value=(val)
        @default_used = false
        @value = val
        if pbMeth = self.proxied_bound_method
          pbMeth.call val
        end
      end
      alias :with_long_form :long_form
    end # end of EachFlag class
  end
end

module OptiFlag
  # testing to see if this shows (1)
  module Flagset
    # top-level flag-declarer
    def flag(flag_name_pair,hash={},&the_block)
      if flag_name_pair.class == String or flag_name_pair.class == Symbol 
        flag_name_pair = [flag_name_pair.to_s,flag_name_pair.to_sym]
      end
      flag = flag_name_pair[0]
      if flag_name_pair[1]
        name = flag_name_pair[1]
      else
        name = flag.to_sym
      end
      @all_flags ||= {} 
      obj = @all_flags[name]      
      obj ||= OptiFlag::Flagset::EachFlag.new(name,flag,self)
      obj.instance_eval &the_block if block_given?
      hash.each_pair do |fxn,val|
        obj.send(fxn,val)
      end
      @all_flags[name] = obj
      return obj
    end    
    # top-level flag-declarer
    def optional_flag(flag_name_pair,hash={},&the_block)
      flag(flag_name_pair,hash,&the_block)
      flag_name_pair = [flag_name_pair] if flag_name_pair.class == String
      name = flag_name_pair[1] || flag_name_pair[0]
      flag_properties name.to_sym do
        optional
      end
    end
    # top-level flag-declarer
    def optional_switch_flag(flag_name_pair,hash={},&the_block)
      flag(flag_name_pair,hash,&the_block)
      flag_name_pair = [flag_name_pair] if flag_name_pair.class == String
      name = flag_name_pair[1] || flag_name_pair[0]
      flag_properties name.to_sym do
        optional
        arity 0
      end      
    end
    # top-level flag-declarer
    def keyword(flag_name_pair,hash={},&the_block)
      @all_keywords ||= []
      @all_keywords << name
      flag(flag_name_pair,hash,&the_block)
      flag_name_pair = [flag_name_pair] if flag_name_pair.class == String
      name = flag_name_pair[1] || flag_name_pair[0]
      flag_properties name.to_sym do
        dash_symbol ""
        long_dash_symbol ""
        arity 0
        optional
      end 
    end
    # top-level flag-declarer
    def flagless_arg(name)
      @all_flagless_arg ||= []
      mine  = flag(name.to_sym)
      @all_flagless_arg << mine
    end
    # top-level flag-declarer
    def usage_flag(*args)
      # to ensure the existence of the @all_flags
      @all_flags ||= {} 
      first,*rest = args

      # the next two statements are necessary because 
      # a user might declare a usage flag, but so might
      # the and_process! method.  We need to make
      # sure that they both refer to the same EachFlag
      any_help_already_set = @all_flags.select {|key,val| val.for_help == true}
      if any_help_already_set[0] != nil 
        # reassign rest to be the orginal first plus the rest
        # UNLESS the first is the exact same one as your previous
        # first -- GOTCHA!!
        rest = [first] + rest if first.to_sym != any_help_already_set[0][0].to_sym
        # and now use the discovered existing help flag key as our new first
        # remember that the optional_flag statement below will
        # merely reopen the existing object stored in the hash
        # instead of creating a new one
        first = any_help_already_set[0][0]
      end
      optional_flag [first] do
        self.for_help = true
        description "Help"
        no_args
        alternate_forms *rest if rest.length > 0
      end
    end
    # top-level flag-declarer
    def extended_help_flag(*args)
      first,*rest = args 
      optional_flag [first] do
        self.for_extended_help = true
        description "Extended Help"
        no_args
        alternate_forms *rest if rest.length > 0
      end
    end
    # top-level flag-declarer
    def character_flag(switch,group="default",&the_block)
      throw "Character switches can only be 1 character long" if switch.to_s.length > 1
      flag(switch.to_sym,&the_block)
      @group ||= {}
      the_flag_we_just_added = @all_flags[switch.to_sym]

      key = [group.to_sym,the_flag_we_just_added.the_dash_symbol]
#      puts "#{ key.join(',')  }"
      @group[key] ||= []
      @group[key] << the_flag_we_just_added
      # re-assert ourselves
      flag [switch.to_s, switch] do
        optional
        arity 0
        compresses
      end
    end
    # top-level flag-declarer
    def flag_properties(symb,hash={},&the_block)
      raise "Block needed for flag_properties" if not block_given? and hash=={}
      @all_flags ||= {} 
      obj = @all_flags[symb.to_sym] 
      return if obj==nil
      obj.instance_eval &the_block if block_given?       
      hash.each_pair do |fxn,val|
        obj.send(fxn,val)
      end
    end
    alias :properties :flag_properties
  end
end

# defining the callable client-interface
module OptiFlag
  module Flagset
    # The NewInterface module is used to augment the ARGV
    # constant with some special methods that it never used
    # to have before.  
    #
    # This is one of two hallmark ideas in making the 
    # OptiFlag suite easier to use:
    # - easy declarative DSL syntax (all the <i>flag set and flag declarations</i>)
    # - and this, an easy to use interface for accessing 
    #   the results *after* the processor has finished processing.
    #
    # To emphasize this point, consider the following declaration:
    #
    #     module AppArgs extend OptiFlagSet
    #       flag "dir"
    #       optional_flag "log"
    #       flag "username"
    #       flag "password"
    #
    #       and_process!
    #     end  
    #
    # Note the <i>special command</i> 'and_process!'
    # This method, which should, by rote, be placed at the end
    # of the DSL-zone (the code internal to the module block)
    # is augmenting the ARGV constant so that the results of the 
    # parsing are now available. Thus:
    #    ARGV.flag_value.dir
    # has a value of whatever the user passed in on the command
    # line for the '-dir' flag.
    # And
    #    ARGV.flag_value.log?
    # tells us whether the user supplied the log flag and if
    # she did, we can access it using 
    #
    #    ARGV.flag_value.log
    # Better looking code would be:
    #    
    #    log_file = ARGV.flag_value.log if ARGV.flag_value.log?
    module NewInterface
      attr_accessor :errors,:flag_value,:specification_errors,:help_requested_on,:warnings
      attr_writer :help_requested,:extended_help_requested
      def errors?
        self.errors != nil
      end
      def warnings?
        self.warnings != nil
      end
      def help_requested?
        @help_requested != nil
      end
      def extended_help_requested?
        @extended_help_requested !=nil
      end
      alias :flags :flag_value 
    end
    class Errors
      attr_accessor :missing_flags,:other_errors,:validation_errors
      def initialize
        @missing_flags,@other_errors,@validation_errors = [],[],[]
      end
      def any_errors?
        @missing_flags.length >0 or @other_errors.length >0 or 
          @validation_errors.length > 0        
      end
      def divulge_problems(output=$stdout)
        output.puts "Errors found:"
        if @missing_flags.length >0
          output.puts "Missing Flags:"
          @missing_flags.each do |x|
            output.puts "   #{ x  }"
          end
        end
        if @other_errors.length >0
          output.puts "Other Errors:"
          @other_errors.each do |x|
            output.puts "   #{ x  }"
          end
        end
        if @validation_errors.length >0
          output.puts "Validation Errors:"
          @validation_errors.each do |x|
            output.puts "   #{ x  }"
          end
        end
      end
    end
    private
    def create_new_value_class()
       klass = Hash.new
       klass.instance_eval do
         def init_with_these(all_objs)
           @all_flags = all_objs
         end
       end
       klass.init_with_these(@all_flags)
       @all_flags.each_value do |y|
         # only allow alphabetic symbols to create methods
         if (y.name.to_s =~ /^[a-zA-Z]+/)
           klass.instance_eval %{
            def #{y.name}()
              @all_flags[:#{ y.name }].value if @all_flags[:#{ y.name }]
            end
            def #{y.name}_details()
              @all_flags[:#{ y.name }] if @all_flags[:#{ y.name }]
            end}
         end
           all_names = [y.name]
           all_names << y.the_alternate_forms if y.the_alternate_forms.length > 0
           all_names.flatten!
           all_names = all_names.select{|x| x.to_s =~ /^[a-zA-Z]+/}
           all_names.each do |x|
           klass.instance_eval %{
            def  #{x}?()
              ret = @all_flags[:#{ y.name }].value
              return false if ret == nil
              if @all_flags[:#{ y.name }] and !@all_flags[:#{ y.name }].default_used
                 return @all_flags[:#{ y.name }].value 
              end 
            end}  
          end
       end
       return klass
     end
        
  end # end of Flagset module
end # end of OptiFlag module



module OptiFlag
    # Special command (at the same level as a <i>flag declaration</i>)
    def OptiFlag.using_object(a_single_object,&the_block)
      class_hierarchy = [a_single_object.class]
      clazz = a_single_object.class
      begin 
        clazz = clazz.superclass
        class_hierarchy << clazz
      end until  clazz != Object
      potential_methods = 
        class_hierarchy.collect{|x|  x.instance_methods(false)}.flatten.sort
        
      require 'enumerator'
      valid_instance_var = []
      potential_opt_switch_flags, potential_methods = 
               potential_methods.partition {|x| x =~ /\?$/ }
      potential_methods.each_slice(2) do |getter,setter|
         if setter.to_s == (getter.to_s + "=") 
           valid_instance_var << [getter,setter]; 
         end  
      end
      mod = Module.new
      mod.extend Flagset
      valid_instance_var.each do |getter,setter|
       bound_method = a_single_object.method(setter)
        mod.instance_eval do
          flag getter do
            self.proxied_bound_method = bound_method 
          end
        end
      end
      mod.instance_eval &the_block if the_block
      mod.instance_eval do
        handle_errors_and_help
      end
    end
      
  # This is a method that looks like a module.  
  # It is an excellent example of the syntactic tricks
  # that ruby permits us.
  # This method allows us to provide code like
  # the following:
  #    module Example extend OptiFlagSet(:flag_symbol => "/")
  #      flag "dir"
  #      flag "log"
  #      flag "username"
  #      flag "password"
  #   
  #      and_process!
  #    end 
  # You will note that the top line looks a lot like
  # the standard top line
  #    # our top line
  #    module Example extend OptiFlagSet(:flag_symbol => "/") 
  # versus
  #    # standard top line
  #    module Example extend OptiFlagSet
  # The difference is that while the latter (a standard
  # top line) is a reference to a module, the former is 
  # a call to this method, that *returns* the OptiFlag::Flagset 
  # module with some defaults changed.
  #
  # As of now the only symbol/method supported by this 
  # method that looks like a module, is the 
  # 'OptiFlag::Flagset.flag_symbol' class method.
  #
  # For those still not understanding the syntactic trick,
  # or who find it odd, consider that something
  # similar to this is done
  # in the ruby core language using the proxy/delegate
  # pattern. (See delegate.rb in the Ruby core library)
  #   class Tempfile < DelegateClass(File)
  #     # ...
  #     # ...
  #   end
  #
  # You will note that the DelegateClass() is also
  # a method that superficially resembles a class
  # that parameterizes itself.  
  # This can be done because Ruby expects:
  #    class <identifier>  <  <expression>
  # and not
  #    class <identifier>  <  <identifier>
  # like some other languages. And likewise
  #    module <identifier> extend  <expression>
  # which allows us to create this method which
  # has the exact same name as the module.
  # Clever ruby.
  def OptiFlag.Flagset(hash)
    # changed this from just returning Flagset...
    # Reason Being:  a user can specify two modules in one file
    # one with this method, and one just using Flagset...
    # if you don't clone at this point, you are left with 
    # a global change... BUT to get the cloning working
    # I had to do some singleton_class trickeration as part of
    # the initialize method for EachFlag... I am not 
    # 100% sure I understand what I just did. -- D.O.E 5/30/06
    mod = Flagset.clone
    hash.each_pair do |symb,val|
      mod.send(symb.to_sym,val)
    end
    return mod
  end

end

module OptiFlag
  module Flagset
    # Special command (at the same level as a <i>flag declaration</i>)
    def handle_errors_and_help(options={})
      return if !@all_flags
      # the next three lines allow me 
      # to increase testability of
      # this function, allowing client code to 
      # simulate ARGV passing without actually
      # depending on ARGV being there
      options[:argv] ||= ARGV  # set it, only if not set
      options[:level] ||= :not_strict # breaks backwards compatability
      argv = options[:argv]
      # the next two lines add the help 
      # flag to the list.
      usage_flag "h","?"  # make this part of the standard config
      properties "h", :long_form=>"help"
      parse(argv,false)
      if argv.help_requested? 
        if !argv.help_requested_on
          show_help
        elsif the_on = argv.help_requested_on
          show_individual_extended_help(the_on.to_sym)
        end
        exit
      end
      if argv.extended_help_requested?
        show_extended_help
        exit
      end
      if argv.errors?
        argv.errors.divulge_problems
#        show_help
        exit
      end
      if argv.warnings? and options[:level] == :with_no_warnings
        puts "In strict warning handling mode.  Warnings will cause process to exit."
        argv.warnings.each do |x|
           puts "   #{ x  }"
        end
        puts "Please fix these warnings and try again."
        exit
      end
      # the next three lines augment the 
      # name of the module that the user
      # has declared... not just argv.
      self.extend NewInterface
      self.flag_value = argv.flag_value
      self.errors = argv.errors
      argv  
    end # end of method handle_errors_and_help
    alias :and_process! :handle_errors_and_help 
  end # end of Flagset
end # end of OptiFlag

module OptiFlag
  # testing to see if this shows (2)
  module Flagset
    attr_accessor  :help_bundle;
    
    private
    def render_help(stdo=$stdout)
      @help_bundle.banner.call stdo
      @all_flags.each_pair do |name_of_flag,flag|
        @help_bundle.help.call stdo, flag
      end
    end
    def show_help(start_message="",stdo=$stdout)
       stdo.puts start_message
       render_help(stdo)
       @all_keywords ||= []
    end
    def show_extended_help(start_message="",stdo=$stdout)
       @all_flags.keys.each do |name|
         show_individual_extended_help(name,stdo)
       end
     end
    def show_individual_extended_help(name,stdo=$stdout)
       the_flag = @all_flags[name]
       return if !the_flag
       extended_help = @help_bundle.extended_help
       extended_help.call stdo, the_flag
     end
  end
end



# Specification error possibilities (at FlagsetDefinition)
#  1) a value_matches and a value_in_set on the same argument
#  2) ambiguous flag names (e.g. two flags both with name -help)
#  3) short symbol flag and long symbol flags match each other
# Specification error possibilities (at DefinitionSwitcher)
#  1)
#  2) 
# Warning conditions
#  1) Left-over arguments 


 # OptiFlag is the module that provides namespacing for the entire
 # optiflag functionality.  For usage and examples, see
 # http://optiflag.rubyforge.org
 #
 # = Terminology
 # Please treat the following terminology as specific only
 # to the OptiFlag code suite. In the remaining RDoc, we shall
 # try to emphasize this consistent terminology with italics.
 # If you see an italicized phrase, chances are that it
 # is defined here.
 # 
 # == Flag Set Declaration
 # A <i>flag set declaration</i> is a set of flag declarations
 # created by the user of the OptiFlag suite and corresponds 
 # to the following code snippet:
 #   module AppArgs extend OptiFlagSet
 #      # individual flag declaration goes here ...
 #      # ... and here
 #   end  
 # In this case, the module *AppArgs* is a <i>flag set declaration</i>,
 # and all code within the module definition (i.e. up to the end of 
 # *end* of the module) is either a <i>flag declaration</i> or a 
 # special command.
 #
 # Another way to treat this declaration is as a demarcation
 # between the normal Ruby world and the mini-DSL (Domain Specific
 # Language) that OptiFlag offers.  In this view,
 # the declaration provides a DSL-zone in which the DSL
 # is allowed.  
 #   module AppArgs extend OptiFlagSet
 #      # DSL-zone 
 #      # DSL-zone  (for declaring and modifying flags)
 #      # DSL-zone 
 #   end  
 # the first line 
 #   module AppArgs extend OptiFlagSet
 # is really just rote.  
 #
 # Supply your own module
 # argument name and make sure it extends this
 # OptiFlag::Flagset as is written. 
 # You will then have a scoped space to write
 # in a command line DSL.
 #
 # == Flag Declaration
 # A <i>flag declaration</i> is placed within a <i>flag set declaration</i>
 # to indicate that one input parameter per declaration is requested
 # from the command line.  A <i>flag declaration</i> is the mini-DSL's main 
 # programming construct. In the following code, four <i>flag declarations</i>
 # are placed within the overall <i>flag *set* declaration</i> named AppArgs:
 #     module AppArgs extend OptiFlagSet
 #       flag "dir"
 #       flag "log"
 #       flag "username"
 #       flag "password"
 #     end  
 # Please note that there are other <i>flag set declaration</i> nouns
 # other than flag.  For instance in the following snippet:
 #     module Example extend OptiFlagSet
 #       flag "dir" do 
 #         alternate_forms "directory","D","d"
 #         description "The Appliction Directory"
 #       end
 #       optional_flag "log" do
 #         description "The directory in which to find the log files"
 #         long_form "logging-directory" # long form is keyed after the '--' symbol
 #       end
 #       flag "username", :description => "Database username."  # alternate form
 #       flag "password" do
 #         description "Database password."
 #       end
 #       usage_flag "h","help","?"
 #       extended_help_flag "superhelp"
 #    
 #       and_process!
 #     end
 # there are six <i>flag declarations</i> in total:
 # * a flag named "dir"
 # * an optional flag named "log"
 # * a flag named "username"
 # * a flag named "password"
 # * a usage flag for summoning help on how to use the flags
 # * an extended help flag for summoning detailed usage for the flags
 # Everything else is either a <i>clause level modifier</i> (e.g.
 # alternate_forms, description, etc.) or a <i>special command</i>.
 #
 # <b>For a list of all <i>flag set declarations</i> and how to
 # use them, see the RDoc for the OptiFlag::Flagset module.</b>
 #
 # == Clause Level Modifier
 # As seen above, a <i>clause level modifier</i> is a word 
 # used to modify the basic flag, usually within a nested do
 # block.  It it this nesting which has inspired the use
 # of the word clause.  For instance:
 #     module Example extend OptiFlagSet
 #       flag "dir" do 
 #         alternate_forms "directory","D","d"
 #         description "The Appliction Directory"
 #       end
 #     end
 # We could read this as a sentence:
 # 'Create a flag "dir" which has three alternate forms "directory", "D", and "d"
 # and which has a description that reads "The Application Directory'.
 #
 # For the most part, these <i>clause level modifiers</i> are nested 
 # within a do-block, though OptiFlag allows us to conserve
 # vertical space by using symbol hashes. (It is recommended
 # that one only uses these in simple cases).  For instance,
 # the following two <i>flag set declarations</i> are
 # equivalent:
 #     module Example extend OptiFlagSet
 #       flag "username", :description => "Database username."  # alternate form
 #    
 #       and_process!
 #     end 
 # and
 #     module Example extend OptiFlagSet
 #       flag "username" do
 #          description "Database username."
 #       end
 #    
 #       and_process!
 #     end 
 # with the first being a syntactically friendly
 # hash of the <i>clause level modifier</i> as a 
 # symbol pointing to the value of the modification.
 #
 # For a complete list of <i>clause level modifiers</i>
 # see the RDoc for OptiFlag::Flagset::EachFlag
 module OptiFlag

 end

OptiFlagSet = OptiFlag::Flagset
def OptiFlagSet(hash)
  OptiFlag::Flagset(hash)
end
