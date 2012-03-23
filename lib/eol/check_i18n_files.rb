# NOTE - this is stolen in order to re-enable a hack we're using to track pre-compiled lines in Haml... I don't care
# to reproduce it. Skip to "Our code starts here" to get to the meat of things.
#
# Haml i18n module providing translation for all Haml plain text calls
# Idea was stolen from
# http://www.nanoant.com/programming/haml-gettext-automagic-translation
#
require 'i18n'

begin
  require 'haml' # From gem
rescue LoadError => e
  # gems:install may be run to install Haml with the skeleton plugin
  # but not the gem itself installed.
  # Don't die if this is the case.
  raise e unless defined?(Rake) && Rake.application.top_level_tasks.include?('gems:install')
end

if defined? Haml
  class Haml::Engine

    #
    # Inject translate into plain text and tag plain text calls
    #
    def push_plain(text)
      push_script "#{text.gsub(/'/, '\\\'')}"
      if !text.empty? && text.gsub(/&[a-z]{1,6};/," ").match(/[a-zA-Z]/) && !text.match(/I18n\./) && !text.gsub("=","").strip.match(/^(h\s|h\(|hh\()/)
        if text.gsub(/#\{.+\}/,"").match(/[a-zA-Z]/)
          if result_array.length > 1
            index=-2
          else
            index=-1
          end
          result_array[index].value = text
          result_array[index].is_plain_text=true
        end
      end
    end

    public
    def parse_tag(line)
      tag_name, attributes, attributes_hash, object_ref, nuke_outer_whitespace,
        nuke_inner_whitespace, action, value = super(line)
      if !value.empty? && value.gsub(/&[a-z]{1,6};/," ").match(/[a-zA-Z]/) && !value.match(/I18n\./) && !value.gsub("=","").strip.match(/^(h\s|h\(|hh\()/)
        new_value = ""
        new_line = ""
        if line.gsub(value,"xxxx").match(/=\s*xxxx/)
          if value.strip.match(/^(=)/)
            new_value = value.strip[1..-1].strip
          elsif value.strip.match(/^('|")/)
            new_value= value.strip[1..-2]
          end
        else
          new_value = value
          if line.sub("%"+tag_name+" ","").strip == value.strip
            new_line = line.sub("%"+tag_name+" ","%"+tag_name)
          end
        end
        if !new_value.gsub(/#\{.+\}/,"").match(/[a-zA-Z]/)
          new_value = ""
        end

        if !new_value.empty?
          if result_array.length > 1
            index=-2
          else
            index=-1
          end
          result_array[index].value = new_value
          result_array[index].is_plain_text=true
          if !new_line.empty?
            result_array[index].line = load_spaces(result_array[index].ident) + new_line
          end
        end
      end
      [tag_name, attributes, attributes_hash, object_ref, nuke_outer_whitespace,
          nuke_inner_whitespace, action, value]
    end

    def load_spaces(count)
      result=""
      for i in 1..count
        result+=" "
      end
      return result
    end

    def result_array
      return @result_array
    end

    class Entry
      attr_accessor :line, :value, :ident, :is_plain_text
      def initialize(line)
        @line = line
        @value = ""
        @ident=0
        @is_plain_text = false
        if whitespace = line.match(/^\s+/)
          @ident = whitespace[0].to_s.length
        end
      end
    end

    def precompile
      @haml_comment = @dont_indent_next_line = @dont_tab_up_next_text = false
      @indentation = nil
      @result_array = []
      @line = next_line
      resolve_newlines
      newline

      raise SyntaxError.new("Indenting at the beginning of the document is illegal.", @line.index) if @line.tabs != 0
      while next_line
        process_indent(@line) unless @line.text.empty?

        if flat?
          push_flat(@line)
          @line = @next_line
          next
        end

        process_line(@line.text, @line.index) unless @line.text.empty? || @haml_comment

        if !flat? && @next_line.tabs - @line.tabs > 1
          raise SyntaxError.new("The line was indented #{@next_line.tabs - @line.tabs} levels deeper than the previous line.", @next_line.index)
        end

        resolve_newlines unless @next_line.eod?
        @line = @next_line
        newline unless @next_line.eod?
      end

      # Close all the open tags
      close until @to_close_stack.empty?
      flush_merged_text
    end

    def next_line
      text, index = raw_next_line
      return unless text

      # :eod is a special end-of-document marker
      line =
        if text == :eod
          Line.new '-#', '-#', '-#', index, self, true
        else
          Line.new text.strip, text.lstrip.chomp, text, index, self, false
        end

      entry = Entry.new(line.full)
      entry.value = (text == :eod) ? "-#" : ""
      result_array << entry

      # `flat?' here is a little outdated,
      # so we have to manually check if either the previous or current line
      # closes the flat block,
      # as well as whether a new block is opened
      @line.tabs if @line
      unless (flat? && !closes_flat?(line) && !closes_flat?(@line)) ||
          (@line && @line.text[0] == ?: && line.full =~ %r[^#{@line.full[/^\s+/]}\s])
        if line.text.empty?
          newline
          return next_line
        end

        handle_multiline(line)
      end

      @next_line = line
    end

    def handle_multiline(line)
      return unless is_multiline?(line.text)
      line.text.slice!(-1)
      i = line.index
      while new_line = raw_next_line.first
        break if new_line == :eod
        newline and next if new_line.strip.empty?
        break unless is_multiline?(new_line.strip)
        line.text << new_line.strip[0...-1]
        result_array << Entry.new(new_line[0..-1])
        newline
      end
      un_next_line new_line
      resolve_newlines
    end

    def handle_ruby_multiline(text)
      text = text.rstrip
      return text unless is_ruby_multiline?(text)
      un_next_line @next_line.full
      begin
        new_line = raw_next_line.first
        break if new_line == :eod
        newline and next if new_line.strip.empty?
        text << " " << new_line.strip
        newline
      end while is_ruby_multiline?(new_line.strip)
      next_line
      resolve_newlines
      text
    end



  end
end

###  Our code starts here.

module EOL
  class CheckI18nFiles

    def initialize
      @lang_dir = File.join([RAILS_ROOT, "config", "locales"])
      @en_yml = File.join([@lang_dir, "en.yml"])
      @failures = false
      puts "** CHECKING I18N FILES..."
      puts "   The following will not register as failing tests. It is up to the developer to handle these issues individually."
      check_consistency
      check_parameter_consistency
      check_hard_coded_controllers
      check_hard_coded_html_erb
      check_hard_coded_html_haml
      check_i18n_keys_have_en_values
      print "** I18N CHECKS COMPLETE. "
      if @failures
        puts "There were #{@failures} failures.  Please address these issues before committing."
      else
        puts green(".. There were no failures, you may commit your code safely.")
      end
    end

    def check_consistency

      en_keys = load_en_keys(@en_yml)
      en_yml_keys = load_yml_file(@en_yml)
      error_message = ''
      missing_keys = ''

      Dir.glob(File.join([@lang_dir, "*"])).each do |file|
        file_name = File.split(file)[-1]
        if file_name != @en_yml && file_name != File.split(@en_yml)[-1] && file_name.match(/^[a-z]{2}\.yml\b/)
          missing_keys << "\n\n" if missing_keys != ''
          missing_keys << file_name + ": \n"

          missing_count = get_missing_keys_count(file, en_keys, missing_keys, en_yml_keys)
          if (missing_count > 0)
            error_message = error_message + "\n" if error_message != ''
            error_message = error_message + missing_count.to_s + " missing keys in " + file_name
          end
        end
      end

      # logging data in log file
      log_file = File.join([RAILS_ROOT, "log", "i18n_missing_keys.txt"]) # if keys are not found in the language files
      log_data = open(log_file, 'w')
      log_data.write missing_keys
      log_data.close

      if (error_message != '')
        error_message << " Please check missing keys at " + log_file
        carp error_message
      end

    end

    def check_parameter_consistency
      error_log = ''
      all_files = get_all_files_in_app
      error_count = 0

      Dir.glob(File.join([@lang_dir, "*"])).each do |file|
        file_name = File.split(file)[-1]
        if file_name.match(/^[a-z]{2}\.yml\b/)
          yml_keys = load_yml_file(file)
          error_log << "\n#{file_name}\n"

          all_files.each do |file|
            inconsistent_keys = get_inconsistent_parameters(file, yml_keys)
            if inconsistent_keys.size > 0
              error_count = error_count + inconsistent_keys.size
              for i in (0..inconsistent_keys.size-1)
                error_log << ">> #{file}\n"
                error_log << "#{inconsistent_keys[i]}\n"
              end
            end
          end
        end
      end
      # logging data in log file
      log_keys = File.join([RAILS_ROOT, "log", "i18n_inconsistent_parameters.txt"]) # for missing keys in en.yml files
      log_data = open(log_keys, 'w')
      log_data.write error_log
      log_data.close

      if (error_count > 0)
        carp error_count.to_s + " keys have incosistent parameters. Please check the missing keys at " + log_keys
      end
    end

    def check_hard_coded_controllers
      log_file = File.join([RAILS_ROOT, "log", "hard_coded_controllers.txt"])
      control_dir = File.join([RAILS_ROOT, "app", "controllers"])
      error_message = ''
      counter=0
      Dir.glob(File.join([control_dir, "**", "*"])).each do |file|
        file_name = File.split(file)[-1]
        if file_name.match(/^[\w]+\.rb\b/)
          control = open(file)

          control.read.each_with_index do |line,index|
            quoted = line.match(/page_title[\s]*=[\s]*([\w]+[\s]*[+][\s]*)*"[\s\w]*"([\s]*[+][\w]+[\s]*)*/)
            if quoted
             counter = counter+1
             error_message = error_message + "\n" + counter.to_s + ". " + file + " line:" + (index+1).to_s + " found: \"" + quoted.to_s + "\""
            end
            quoted = line.match(/flash[\s]*[\[][\s]*:[\s]*[\w]+[\s]*[\]][\s]*=[\s]*([\w]+[\s]*[+][\s]*)*"[\s\w]*"([\s]*[+][\w]+[\s]*)*/)
            if quoted
             counter = counter+1
             error_message = error_message + "\n" + counter.to_s + ". " + file + " line:" + (index+1).to_s + " found: \"" + quoted.to_s + "\""
            end
          end
        end
      end

      if (error_message!='')
        # logging data in log file
        log_data = open(log_file, 'w')
        log_data.write error_message
        log_data.close
        error_message = "\n"+counter.to_s+" hard coded page titles and flash in app/controllers/*. Please check log file for more details at "+log_file
        carp error_message
      end
    end

    def check_hard_coded_html_erb
      log_file = File.join([RAILS_ROOT, "log", "hard_coded_html_erb.txt"])
      control_dir = File.join([RAILS_ROOT, "app", "views"])
      error_message = ''
      counter=0
      Dir.glob(File.join([control_dir, "**", "*"])).each do |file|
        file_name = File.split(file)[-1]
        if file_name.match(/^[\w]+\.html.erb\b/)
          control = open(file)
          control.read.each_with_index do |line, index|
            quoted = line.match(/>[\s]*[^<>]+[\s]*/)
            matchString = "=" + quoted.to_s
            if quoted && line.scan(matchString).empty? && quoted.to_s.strip.match(/[a-zA-Z]+/) && quoted.to_s.scan("www.").empty? && quoted.to_s.scan("http:").empty?
              counter = counter + 1
              error_message = error_message + "\n" + counter.to_s + ". " + file + " line:" + (index+1).to_s + " found: \"" + quoted.to_s + "\""
            else
              quoted = line.match(/[\s]*[a-zA-Z ]+[\s]*</)
              if quoted && quoted.to_s.strip.match(/[a-zA-Z]+/) && quoted.to_s.scan("www.").empty? && quoted.to_s.scan("http:").empty?
                counter = counter + 1
                error_message = error_message + "\n" + counter.to_s + ". " + file + " line:" + (index+1).to_s + " found: \"" + quoted.to_s + "\""
              end
            end
          end
        end
      end

      if (error_message!='')
         # logging data in log file
        log_data = open(log_file, 'w')
        log_data.write error_message
        log_data.close
        error_message = "\n" + counter.to_s + " hard coded string found in app/views/*.html.erb. Please check log file for more details at "+log_file
        carp error_message
      end
    end

    def check_hard_coded_html_haml
      log_file = File.join([RAILS_ROOT, "log", "hard_coded_html_haml.txt"])
      counter=0;
      error_message = ''
      Dir.glob(File.join([RAILS_ROOT, "app", "views", "**", "*"])).each do |file|
        if file.match(/(\.html.haml)$/)
          begin
            haml_engine = Haml::Engine.new(File.read(file))
            haml_engine.precompiled
          rescue
            #error_message = error_message + "\nHAML parser failed for file : "+file + "\n"
            next
          end
          parent_ident = 0
          skip = false
          haml_engine.result_array.each_with_index do |entry,index|
            sline = entry.line.strip
            #Empty lines
            if entry.line == "-#" && entry.value == "-#"
              next
            end
            if sline.empty?
              next
            end
            #javascript or %style
            if skip == true
              if entry.ident > parent_ident
                next
              else
                skip = false
              end
            end
            if sline.match(/^(:javascript)/) || sline.match(/^(%style)/) || sline.match(/^(%script)/)
              skip = true
              parent_ident = entry.ident
              next
            end
            #Value exist
            if !entry.value.empty?
              counter = counter+1
              error_message = error_message + "\n"+ counter.to_s + ". " + file+" line:"+(index+1).to_s+" found: "+entry.line.strip
            elsif handle(entry.line) == true
              counter = counter+1
              error_message = error_message + "\n" + counter.to_s+". " + file+" line:"+(index+1).to_s+" found: "+entry.line.strip
            end
          end
        end
      end

      if (error_message!='')
        # logging data in log file
        log_data = open(log_file, 'w')
        log_data.write error_message
        log_data.close
        error_message = "#{counter} Hard-coded strings found in app/views/*.html.haml. Please check log file for more details at "+log_file
        carp error_message
      end
    end

    def check_i18n_keys_have_en_values

      missing_log = ''
      en_yml_keys = load_yml_file(@en_yml)

      all_files = get_all_files_in_app

      all_files.each do |file|
        temp_string = get_missing_keys_in_file(file, en_yml_keys)
        if (temp_string) != ""
          missing_log << "\n" if missing_log != ""
          missing_log << temp_string
        end
      end

      # logging data in log file
      log_keys = File.join([RAILS_ROOT, "log", "i18n_missing_en_keys.txt"]) # for missing keys in en.yml files
      log_data = open(log_keys, 'w')
      log_data.write missing_log
      log_data.close

      missing_count = missing_log.split("\n").size
      if (missing_count > 0)
        carp missing_count.to_s + " keys were missing. Please check the missing keys at " + log_keys
      end

    end

  private

    def carp(why)
      @failures ||= 0
      @failures += 1
      puts red("** ERROR: #{why}")
    end

    def key_exists(key, en_yml_keys)
      if en_yml_keys[key]
        return true
      else
        return false
      end
    end

    def get_keys(file_content)

      # returns array of keys in the file if any
      keys = Array.new
      temp_keys = file_content.split(/I18n.t(ranslate)*/)
      if (temp_keys.size==1)
        # no I18n keys in this file, return an empty array
        return keys
      else
        # ignore the first item in the array, from the second item, each will start with the key
        keys_count = 0
        for i in (1..temp_keys.size-1)
          if temp_keys[i].match(/^(\s*\()/) # matchs I18n.t(xxxx)
            if temp_keys[i].strip != '(' # to avoid error from nested I18n.t
              temp_str = temp_keys[i].strip.gsub('(','').strip.split(")")[0].split(",")[0]
              if (temp_str.index("\"") or temp_str.index("'") or temp_str.index(":"))
                keys[keys_count] = temp_str.strip.gsub("\"", "").gsub(":","").gsub("'","")
                keys_count = keys_count + 1
              end
            end
          elsif temp_keys[i].match(/^\s(\')/) # matchs I18n.t 'xxx'
            temp_str = temp_keys[i].strip[1..-1].split("'")[0] # trim then remove the first ' then split on the next ' and get the key
            keys[keys_count] = temp_str.strip
            keys_count = keys_count + 1
          elsif temp_keys[i].match(/^\s(\")/) # matchs I18n.t "xxx"
            temp_str = temp_keys[i].strip[1..-1].split('"')[0] # trim then remove the first " then split on the next " and get the key
            keys[keys_count] = temp_str.strip
            keys_count = keys_count + 1
          elsif temp_keys[i].match(/^\s(\:)/) # matchs I18n.t :xxx
            temp_str = temp_keys[i].strip[1..-1].split(/(,|\s|$|\Z)/)[0] # trim then remove the first : then split on the next comma, space, or a new line, end of line, or end of string
            keys[keys_count] = temp_str.strip
            keys_count = keys_count + 1
          end
        end
        return keys
      end

    end

    def load_parameters_from_key(value)
      return_array = Array.new
      if value.index('%{')
        temp_array = value.split('%{')
        for i in (1..temp_array.size-1)
          return_array << temp_array[i].split('}')[0]
        end
      end
      return return_array
    end

    def load_full_i18_function_call(function_parameters)
      string_in_lines = function_parameters.split("\n")
      i=0
      current_line = string_in_lines[i]
      return_call = current_line

      while (current_line.strip[-1] == ',' and i < string_in_lines.size)
        i = i + 1
        return_call << " " + current_line
        current_line = string_in_lines[i]
      end

      return return_call
    end

    def check_call_inconsistency(yml_keys, key_name, function_call)
      if (yml_keys[key_name])
        params = load_parameters_from_key(yml_keys[key_name])
        for i in (0..params.size-1)
          if (function_call.split(":"+params[i]).size > 1)
            equal_index = function_call.split(":"+params[i])[1].strip.index("=>")
            if equal_index.nil? or equal_index>0
              return true
            end
          else
            return true
          end
        end
      end
      return false
    end

    def get_inconsistent_parameters(file_path, yml_keys)
      file_open = open(file_path, "r")
      file_content = file_open.read
      file_open.close

      # returns array of keys in the file if any
      keys_having_incorrect_parameters = Array.new
      temp_keys = file_content.split(/I18n.t(ranslate)*/)
      if (temp_keys.size==1)
        # no I18n keys in this file, return an empty array
        return keys_having_incorrect_parameters
      else
        # ignore the first item in the array, from the second item, each will start with the key
        keys_count = 0
        for i in (1..temp_keys.size-1)
          if temp_keys[i].match(/^(\s*\()/) # matchs I18n.t(xxxx)
            if temp_keys[i].strip != '(' # to avoid error from nested I18n.t
              function_call = temp_keys[i].strip.gsub('(','').strip.split(")")[0]
              key_name = function_call.split(')')[0].strip.gsub("\"", "").gsub(":","").gsub("'","")
              if check_call_inconsistency(yml_keys, key_name, function_call)
                keys_having_incorrect_parameters << key_name
              end
            end
          elsif temp_keys[i].match(/^\s(\')/) # matchs I18n.t 'xxx'
            key_name = temp_keys[i].strip[1..-1].split("'")[0] # trim then remove the first ' then split on the next ' and get the key
            full_call = load_full_i18_function_call(temp_keys[i])
            if check_call_inconsistency(yml_keys, key_name, full_call)
              keys_having_incorrect_parameters << key_name
            end
          elsif temp_keys[i].match(/^\s(\")/) # matchs I18n.t "xxx"
            key_name = temp_keys[i].strip[1..-1].split('"')[0].strip # trim then remove the first " then split on the next " and get the key
            full_call = load_full_i18_function_call(temp_keys[i])
            if check_call_inconsistency(yml_keys, key_name, full_call)
              keys_having_incorrect_parameters << key_name
            end
          elsif temp_keys[i].match(/^\s(\:)/) # matchs I18n.t :xxx
            key_name = temp_keys[i].strip[1..-1].split(/(,|\s|$|\Z)/)[0].strip # trim then remove the first : then split on the next comma, space, or a new line, end of line, or end of string
            full_call = load_full_i18_function_call(temp_keys[i])
            if check_call_inconsistency(yml_keys, key_name, full_call)
              keys_having_incorrect_parameters << key_name
            end
          end
        end
        return keys_having_incorrect_parameters
      end

    end

    def get_missing_keys_in_file(file_path, en_yml_keys)
      file_open = open(file_path, "r")
      file_content = file_open.read
      file_open.close

      translations = get_keys(file_content)

      if translations.size == 0
        return ""
      else
        results = []
        translations.each do |key|
          val = I18n.t(key)
          next if val.is_a? Hash # It exists... but requires arguments.
          next if key =~ /\{.*}/ # We cannot reliably predict keys with variables in them.
          if val =~ /^translation missing:/
            results << "#{file_path}: #{key}"
          end
        end
        return results.join("\n")
      end

    end

    def get_all_files_in_app
      Dir.chdir(File.join([RAILS_ROOT, "app"]))
      return Dir.glob(File.join("**", "*.{rb,haml,erb}"))
    end

    def stripHTML(str)
      matchTag = /<(?:.|\s)*?>/
      return str.gsub(matchTag, "")
    end


    def check_is_found(value)
      value = stripHTML(value.strip)
      if !value.empty? && value.gsub(/#\{.+\}/,"").match(/[a-zA-Z]/)
        return true
      end
      return false
    end

    def handle(line)
      found = false
      #link_to
      if tag = line.match(/link_to[\w]*\s*\(?/)
        result = line.split(tag[0])[1]
        if text = result.match(/^(("[^"]+")|('[^']+'))/)
          value = text[0].strip
          if check_is_found(value)==true
      return true
          end
        end
        if confirm = result.match(/:confirm\s*=>\s*(("[^"]+")|('[^']+'))/)
          value = confirm[0].gsub(/:confirm\s*=>\s*/,"").strip
          if check_is_found(value)==true
            return true
          end
        end
      end
      #image_tag
      if tag = line.match(/image_tag[\w]*\s*\(?/)
        if result = line.match(/:title\s*=>\s*(("[^"]+")|('[^']+'))/)
          value = result[0].gsub(/:title\s*=>\s*/,"").strip
          if check_is_found(value)==true
            return true
          end
        end
        if result = line.match(/:alt\s*=>\s*(("[^"]+")|('[^']+'))/)
          value = result[0].gsub(/:alt\s*=>\s*/,"").strip
          if check_is_found(value)==true
      return true
          end
        end
      end
      #%a %img %link %span %label
      if tag = line.match(/(%a|%img|%link|%span|%label)[\#\.\{\s]/)
        if result = line.match(/:alt\s*=>\s*(("[^"]+")|('[^']+'))/)
          value = result[0].gsub(/:alt\s*=>\s*/,"").strip
          if check_is_found(value)==true
            return true
          end
        end
        if result = line.match(/:title\s*=>\s*(("[^"]+")|('[^']+'))/)
          value = result[0].gsub(/:title\s*=>\s*/,"").strip
          if check_is_found(value)==true
      return true
          end
        end
      end
      #submit_tag f.submit
      if tag = line.match(/=\s*(submit_tag|f.submit)\s*\(?/)
        if line.split(tag[0]).length > 1
          result = line.split(tag[0])[1]
          if text = result.match(/^(("[^"]+")|('[^']+'))/)
            value = text[0].strip
            if check_is_found(value)==true
        return true
            end
          end
          if confirm = result.match(/:confirm\s*=>\s*(("[^"]+")|('[^']+'))/)
            value = confirm[0].gsub(/:confirm\s*=>\s*/,"").strip
            if check_is_found(value)==true
              return true
            end
          end
        end
      end
      #f.label
      if(tag = line.match(/=\s*(f.label)\s*\(?/))
        if line.split(tag[0]).length>1
          result = line.split(tag[0])[1]
          if text = result.gsub("\\\"","xxx").gsub("\\\'","yyy").match(/,\s*(("[^"]+")|('[^']+'))/)
            value = text[0].strip[1..-1].strip
            if check_is_found(value)==true
              return true
            end
          end
        end
      end
      return false
    end

    def load_en_keys(en_yml)
      # return array of keys
      en = open(en_yml)
      en_keys = Array.new
      key_count = 0
      en.read.each do |line|
        key = line.match(/^\s\s(\s*)([\w_?]*):\s/)
        if key
          key = key[1] if key
          if key
            en_keys[key_count] = key
            key_count = key_count + 1
          end
        end
      end
      en.close

      return en_keys
    end

    def load_yml_file(file_path)
      read_file = open(file_path)
      file_content = ''
      read_file.read.each do |line|
        if line.match(/^\s\s(\s*)([\w_?]*):\s/)
          file_content << line
          file_content << "\n"
        end

      end
      read_file.close
      begin
        yaml = YAML.load(file_content)
        return yaml
      rescue => e
        raise "** ERROR: Could not parse '#{file_path}': #{e.message}"
      end
    end

    def get_missing_keys_count(file_path, en_keys, missing_keys, en_yml_keys)
      # returns number of missing keys at the langauge file comparing with the en file
      missing_count = 0
      lang_yml = load_yml_file(file_path)
      en_keys.each do |key|
        if (((!lang_yml[key]) or lang_yml[key] == '') and en_yml_keys[key])
          missing_count = missing_count + 1
          missing_keys << " " + key + ": \"" + en_yml_keys[key] + "\"\n"
        end
      end
      return missing_count
    end

    def colorize(text, color_code)
      "\e[#{color_code}m#{text}\e[0m"
    end

    def red(text); colorize(text, 31); end
    def green(text); colorize(text, 32); end


  end
end
