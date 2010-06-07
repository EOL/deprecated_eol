module OptiFlag
  module Flagset
    def parse(args,clone=true)
      init_help_bundle()
      safe_args = args.clone.compact if clone
      safe_args = args if ! clone
      # the following 10 lines were changed so
      # that a module could reparse a command-line
      # and not have a global-state change for
      # everyone... I had mulled just mandating that
      # a SomeArgModule::parse(ARGV) statement 
      # could only occur once, but since everything else
      # is getting ugly, might as well allow this
      # --D.O.E 5/30/2006
      new_self = self.clone
      new_flags = {} 
      @all_flags.each_pair do |key,val|
        val = val.clone
        new_flags[key] = val
      end
      new_self.module_eval do
        @all_flags = new_flags
        safe_args = search_for_missing_character_switches(safe_args) 
        safe_args = create_api(safe_args)
        safe_args = search_for_missing_flags(safe_args) 
        populate_values(safe_args)
        now_populate_hash(@all_flags,safe_args)
      end
      return safe_args
     end 
    
    private
    def init_help_bundle
      # thank god for the ||= operator
      @help_bundle ||= OptiFlag::Flagset::Help::StandardHelpBundle
    end
    def now_populate_hash(all_flags,safe_args)
      all_flags.each_pair do |k,v| 
        safe_args.flag_value[k.to_sym] = v.value
        v.the_alternate_forms.each do |x|

          safe_args.flag_value[x.to_sym] = v.value
        end
      end
    end
     def find_help_flags(safe_args)
       arg_copy = safe_args.clone.compact

       #first we get rid of all non-help flags... 
       non_help_flags = @all_flags.values.select{|value| !value.for_help }
       non_help_flags.each do |val|
          flag_finder_and_stripper(val.as_the_form_that_is_actually_used,val.the_arity,arg_copy)
       end
       # ...because the help flag is overloaded... it can have an arity of 0 or 1
       help_flag = @all_flags.values.select{|value|  value.for_help }
       if help_flag.length > 0
         flag = help_flag[0].as_the_form_that_is_actually_used

         found,discard = flag_finder_and_stripper(flag,1,arg_copy)
         if found.length > 0

           safe_args.help_requested = true
           if found.length == 2
             safe_args.help_requested_on = found[1]
           end
         end
       end     
       arg_copy = safe_args.clone.compact

       ext_help_flag = @all_flags.values.select{|value| value.for_extended_help }
       if ext_help_flag.length > 0
         flag = ext_help_flag[0].as_the_form_that_is_actually_used

         found,discard = flag_finder_and_stripper(flag,0,arg_copy)
         if found.length > 0
           safe_args.extended_help_requested = true
         end
       end 
     end
     def flag_finder_and_stripper(flag,arity,args)
       args = args.compact
       idx = args.index(flag)
       if idx == nil 
         return [], args
       end
       the_range = idx..(idx + arity)
       fragment = args[the_range].clone.compact
       args[the_range] = nil
       return fragment, args.compact
     end
     def populate_values(safe_args)
       safe_args = find_the_flag_that_is_actually_used(safe_args)
       arg_copy = safe_args.clone.compact
       @all_flags.values.each do |flag_obj|

         the_string_flag = flag_obj.as_the_form_that_is_actually_used
         flag_and_values, arg_copy = 
             flag_finder_and_stripper(the_string_flag,flag_obj.the_arity,arg_copy)
         if flag_and_values.length >2
           discard,*theRest = flag_and_values
           flag_obj.value = theRest
         end
         flag_obj.value = flag_and_values[1] if flag_and_values.length ==2
         flag_obj.value = true if flag_and_values.length == 1  and flag_obj.the_arity == 0

         if flag_and_values.length == 1 and flag_obj.the_arity >0

           problem = "Argument(s) missing for flag : #{ flag_obj.as_the_form_that_is_actually_used }"
           safe_args.errors ||= OptiFlag::Flagset::Errors.new
           safe_args.errors.validation_errors << problem
         end
       end
       if arg_copy.length > 0 # is there anything left over
         safe_args.warnings ||= []
         safe_args.warnings << 
                  "There are extra arguments left over: [#{ arg_copy.join(', ') }]. "
       end
       validate_values(safe_args)
       find_help_flags(safe_args)

       return safe_args
     end     
     def validate_values(safe_args)
       run_pre_translate(safe_args)
       # validate generic now handles all validations
       validate_generic(safe_args)
       run_post_translate(safe_args)
     end
     # find all flags the have validation rules assigned to them
     # i.e. any flag that has values set in the array 
     # the_validation_rules.  Each value in this array is a 
     # proc/lambda/block that accepts two arguments:  the flag
     # of class EachClass and the errors array.  
     def validate_generic(safe_args)
       flags_requiring_validation = @all_flags.values.select do |x| 
         x.the_validation_rules.length > 0 && ( x.value != nil)
       end
       flags_requiring_validation.each do |flag_obj|
         value = flag_obj.value
         flag_obj.the_validation_rules.each do |proc|
           errors = safe_args.errors
           errors ||= OptiFlag::Flagset::Errors.new
           proc.call flag_obj, errors.validation_errors
           if errors.validation_errors.length > 0 
             safe_args.errors = errors
           end
         end
       end
     end
     def run_pre_translate(safe_args)
       # find all flags that require pre-translation, i.e.
       # all flags that 1) have a value and 2) have the the_pretranslate
       # attribute flagged as on
       flags_requiring_pre_translating = @all_flags.values.select do |x|
          x.the_pretranslate && x.value
       end
       # the symbol passed as the second argument is the means by which we
       # fetch the translation block
       standard_translating(flags_requiring_pre_translating,:the_pretranslate)
     end
     def run_post_translate(safe_args)
       # find all flags that require post-translation, i.e.
       # all flags that 1) have a value and 2) have the the_posttranslate
       # attribute flagged as on
       flags_requiring_post_translating = @all_flags.values.select do |x|
          x.the_posttranslate && x.value
       end
       standard_translating(flags_requiring_post_translating,:the_posttranslate)
     end
     def standard_translating(arr,pre_or_post)
       arr.each do |flag|
          flag.send(pre_or_post).each_with_index do |translate,idx|
           the_value = flag.value
           the_value = [the_value] if the_value.class != Array
           if translate.arity > 1
             retVal = translate.call *the_value 
             retVal ||= []
             retVal = [retVal] if retVal.class !=Array
             if retVal.length != translate.arity
               raise "Error: the translate block you used had #{ translate.arity  } arguments, but your block returned #{ retVal.length } values.  They must be equal."
             end 
             flag.value = retVal
           elsif translate.arity == 1
             retVal = translate.call(the_value[idx]) 
             flag.value[idx] = retVal
           end
          end
       end
     end
     # private method
     def find_the_flag_that_is_actually_used(safe_args)
       there_might_be_errors = safe_args.errors || OptiFlag::Flagset::Errors.new
       args_copy = safe_args.clone.compact
       @all_flags.values.each do |x|
         shortform,longform = x.as_string_basic,x.as_string_extended
         all_forms = [shortform,longform] + x.as_alternate_forms     
         form_found_mask = all_forms.collect do |form|
           is_form_found, args_copy = 
             flag_finder_and_stripper(form,x.the_arity,args_copy)
           [ (is_form_found.length > 0), is_form_found ]
         end
         any_found = form_found_mask.select{|(found,parms)| found}   
         if any_found.length > 1
           there_might_be_errors.other_errors << 
                        "More than one flag form of -- is present. This is ambiguous. Choose one only."
         end
         if any_found.length == 1
           x.the_form_that_is_actually_used = any_found[0][1][0]
         end  
       end
       if there_might_be_errors.any_errors?
         safe_args.errors = there_might_be_errors
       end
       return safe_args
     end
     def search_for_missing_character_switches(safe_args)
       these_args = safe_args.clone.compact
       return safe_args if @group == nil
       chars_found_for_this_group = {}
       all_chars = ""
       @group.each_pair do |k,val|         
         name_of_flag = val.collect{|x|  x.name}
         all_chars_alphabetical = name_of_flag.join('').unpack('c*').sort.pack('c*')
         args_namespaced = these_args.select{|x| x.match("^#{ k[1] }")  }
         seems_to_match = []
         args_namespaced.each do |flag|
           flag_value = flag.match("^#{ k[1]}").post_match
           potential = all_chars_alphabetical.tr(flag_value,"")
           if potential.length == all_chars_alphabetical.length - flag_value.length
             seems_to_match << flag_value
             all_chars_alphabetical = all_chars_alphabetical.tr(flag_value,"")
             these_args = these_args - [flag] 
           end
         end
         seems_to_match = seems_to_match.flatten.join('')
         chars_found_for_this_group[k] = seems_to_match
         all_chars << seems_to_match
       end       
       all_chars.split(//).each do |x|
         opt_flag = @all_flags[x.to_sym]
         opt_flag.value = true
       end
       
       return safe_args
     end

     def search_for_missing_flags(safe_args)
       there_might_be_errors = OptiFlag::Flagset::Errors.new
       required_flags = @all_flags.values.sort do |x,y| 
         x.order_added <=> y.order_added 
       end.select{ |x| x.the_is_required }
       #puts "Required flags #{required_flags}"
       args_copy = safe_args.clone.compact
       required_flags.each do |x| 
         shortform,longform = x.as_string_basic,x.as_string_extended
         all_forms = [shortform,longform] + x.as_alternate_forms

         form_found_mask = all_forms.collect do |form|
           is_form_found, args_copy = 
             flag_finder_and_stripper(form,x.the_arity,args_copy)
           [ (is_form_found.length > 0), is_form_found ]
         end
         is_first_found,is_second_found = form_found_mask
         any_found = form_found_mask.select{|(found,parms)| found}
         if any_found.length == 0
           there_might_be_errors.missing_flags  <<  x.as_string_basic
         end
         if is_second_found[0]  && is_first_found[0]
           there_might_be_errors.other_errors << 
                        "Both forms #{ x.as_string_basic } and #{x.as_string_extended  } are present. This is ambiguous. Choose one only."
         end
         if any_found.length == 1
           x.the_form_that_is_actually_used = any_found[0][1][0]
         end
       end
       if there_might_be_errors.any_errors?
         safe_args.errors = there_might_be_errors
       end
       return safe_args
     end
     def create_api(safe_args)
       safe_args.extend OptiFlag::Flagset::NewInterface
       safe_args.flag_value =  create_new_value_class()
       return safe_args
     end
  end
end
