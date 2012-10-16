require 'haml'
require 'i18n'

desc 'Tasks useful for extracting raw text for internatiolization'

namespace :i18n do

  lang_dir = Rails.root.join("config", "locales")
  en_yml = File.join(lang_dir, "en.yml")

  desc 'Extract row text from haml code'
  task :extract_text => :environment do
  include ActionView::Helpers

    def replace_line(line, value, en_yml)
      if !value.empty? && value.gsub(/#\{.+\}/,"").match(/[a-zA-Z]/)
        line = line.gsub(value,process_string(value[1..-2],en_yml,false))
      end
      return line
    end
   

    def handle(line,en_yml)
      #link_to
      if tag = line.match(/link_to[\w]*\s*\(?/)
        result = line.split(tag[0])[1]
        if text = result.match(/^(("[^"]+")|('[^']+'))/)
          value = text[0].strip
          line = replace_line(line,value,en_yml)
        end
        if confirm = result.match(/:confirm\s*=>\s*(("[^"]+")|('[^']+'))/)
          value = confirm[0].gsub(/:confirm\s*=>\s*/,"").strip
          line = replace_line(line,value,en_yml)
        end
      end
      #image_tag
      if tag = line.match(/image_tag[\w]*\s*\(?/)
        if result = line.match(/:title\s*=>\s*(("[^"]+")|('[^']+'))/)
          value = result[0].gsub(/:title\s*=>\s*/,"").strip
          line = replace_line(line,value,en_yml)
        end
        if result = line.match(/:alt\s*=>\s*(("[^"]+")|('[^']+'))/)
          value = result[0].gsub(/:alt\s*=>\s*/,"").strip
          line = replace_line(line,value,en_yml)
        end
      end
      #%a %img %link %span %label
      if tag = line.match(/(%a|%img|%link|%span|%label)[\#\.\{\s]/)
        if result = line.match(/:alt\s*=>\s*(("[^"]+")|('[^']+'))/)
          value = result[0].gsub(/:alt\s*=>\s*/,"").strip
          line = replace_line(line,value,en_yml)
        end
        if result = line.match(/:title\s*=>\s*(("[^"]+")|('[^']+'))/)
          value = result[0].gsub(/:title\s*=>\s*/,"").strip
          line = replace_line(line,value,en_yml)
        end
      end
      #submit_tag f.submit
      if tag = line.match(/=\s*(submit_tag|f.submit)\s*\(?/)
        if line.split(tag[0]).length > 1
          result = line.split(tag[0])[1]
          if text = result.match(/^(("[^"]+")|('[^']+'))/)
            value = text[0].strip
            line = replace_line(line,value,en_yml)
          end
          if confirm = result.match(/:confirm\s*=>\s*(("[^"]+")|('[^']+'))/)
            value = confirm[0].gsub(/:confirm\s*=>\s*/,"").strip
            line = replace_line(line,value,en_yml)
          end
        end
      end
      #f.label
      if(tag = line.match(/=\s*(f.label)\s*\(?/))
        if line.split(tag[0]).length>1
          result = line.split(tag[0])[1]
          if text = result.gsub("\\\"","xxx").gsub("\\\'","yyy").match(/,\s*(("[^"]+")|('[^']+'))/)
            value = text[0].strip[1..-1].strip
            line = replace_line(line,value.gsub("xxx","\"").gsub("yyy","\'"),en_yml)
          end
        end
      end
      return line
    end #end handle

    def count_file_lines(file)
       arr = File.readlines(file)
       size = arr.size
       while size>0 do
         if arr[size-1].strip.empty?
           size = size-1;
         else
           break
         end
       end
       return size
    end
    
    def process_file(source_file, en_yml)
      template = File.read(source_file)
      haml_engine = Haml::Engine.new(template)
      haml_engine.precompiled
      parent_ident = 0
      skip = false
      file_content = ""
      count_old = count_file_lines(source_file)
      count_new = haml_engine.result_array.size-2
      if count_old != count_new
        puts "======== File Parsing Error: number of lines mismatch, but parsing continued... =========="
      end
      haml_engine.result_array.each do |entry|
        sline = entry.line.strip
        #Empty lines
        if entry.line == "-#" && entry.value == "-#"
          next
        end
        if sline.empty?
          file_content << entry.line + "\n"
          next
        end
        #javascript or %style
        if skip == true
          if entry.ident > parent_ident
            file_content << entry.line + "\n"
            next
          else
            skip = false
          end
        end
        if sline.match(/^(:javascript)/) || sline.match(/^(%style)/) || sline.match(/^(%script)/)
          skip = true
          file_content << entry.line + "\n"
          parent_ident = entry.ident
          next
        end
        #Value exist
        if !entry.value.empty?
          entry.line = entry.line.gsub("\\"+entry.value,entry.value)
          if entry.line.gsub(entry.value,"xxxx").match(/==\s*xxxx/)
            entry.line = entry.line.sub(/==\s*/,"")
          elsif entry.line.gsub(entry.value,"xxxx").match(/\"xxxx\"/) || entry.line.gsub(entry.value,"xxxx").match(/'xxxx'/)
            entry.line = entry.line.gsub("\""+entry.value+"\"",entry.value).gsub("'"+entry.value+"'",entry.value)
            entry.is_plain_text=false
          end
          entry.line = entry.line.gsub(entry.value, process_string(entry.value, en_yml, entry.is_plain_text)) + "\n"
          file_content << entry.line
        else
           entry.line = handle(entry.line,en_yml) + "\n"
           file_content << entry.line
        end
      end
      return file_content
    end
    


    def check_if_string_exists(string, en_yml)
      en = open(en_yml)
      en.read.each do |line|
        if line.match(/^\s\s([\w_?]*):\s/)
          if (line.split(': "')[1].rstrip == string.gsub("\"", "\\\"")+'"')
            return line.split(': "')[0].strip
            exit
          end
        end
      end
      return ''
    end
    
    def check_for_duplicated_key(key, en_yml)
      en = open(en_yml)
      en_content = ''
      en.read.each do |line|
        if line.match(/^\s\s([\w_?]*):\s/)
          en_content << line.strip
          en_content << "\n"
        end
      end
      en.close
      en_data = YAML.load(en_content)
      while en_data[key] do
        key << '_'
      end
      return key
    end
    
    def generate_key(string_value)
      string_array = string_value.split('')
      return_string = ''
      for i in (0..string_array.length-1)
        if (i==string_array.length-1 and string_array[i]==".")
          #puts 'escaping last . in the line'
        else
          if (string_array[i].match(/[a-zA-Z0-9]/))
            return_string << string_array[i].downcase
          else
            if (string_array[i]!='#' and string_array[i]!='{' and string_array[i]!='}' and string_array[i]!='%')
              return_string << '_'
            end
          end
        end
      end
      if (return_string.length>30)
        return_string = return_string[0,30]
      end
      return return_string
    end
    
    def generate_variable(string_value)
      string_array = string_value.split('')
      return_string = 'var_'
      for i in (0..string_array.length-1)
        if (string_array[i].match(/[a-zA-Z0-9]/))
          return_string << string_array[i].downcase
        else
          return_string << '_'
        end
      end
      return return_string
    end
  
    def write_to_en_yml_file(en_yml, key, value)
      en_file = open(en_yml, 'a')
      en_file.write " " + key + ": \"" + value.gsub("\"", "\\\"") + "\"\n"
      en_file.close
    end

    def process_string(string_value, en_yml, is_plain_text)
      key_array = Array.new
      variable_array = Array.new
      
      output_string = string_value
      hash_count = 0
      if (string_value.include? '#{')
        temp_array = string_value.split('#{')
        for i in (1..temp_array.length-1)
          hash_count = hash_count + 1
          temp_string = temp_array[i].split('}')[0]
          variable_array[i] = temp_string
          key_array[i] = generate_variable(temp_string)
          output_string = output_string.gsub('#{'+temp_string+'}','%{'+key_array[i]+'}')
        end
      end
       
      string_key = check_if_string_exists(output_string, en_yml)
      if (string_key == '')
        string_key = check_for_duplicated_key(generate_key(output_string), en_yml)
        write_to_en_yml_file en_yml, string_key, output_string
      end
     
      output_str=""
      if is_plain_text
        output_str = "="
      end
      output_str << 'I18n.t("' + string_key + '"'
      for i in (1..hash_count)
        output_str << ', :' + key_array[i] + ' => ' + variable_array[i]
      end
      
      output_str << ')'
      
      return output_str
    end

    def write_file(file_path, file_content)
      haml_file = open(file_path, 'w')
      haml_file.write file_content
      haml_file.close
    end


    def modify_views(en_yml)
      Dir.glob(Rails.root.join("app", "views", "**", "*")).each do |file|
        #file = "/EOL/20110412/eol/app/views/taxa/videos.html.haml"
        if file.match(/(\.html.haml)$/)
          puts "\n## "+file
          begin
            file_content = process_file(file, en_yml)
          rescue
            puts "======== File Parsing Error: Haml code error, parsing skiped=========="
          end
          begin
            haml_engine = Haml::Engine.new(file_content)
            haml_engine.precompiled
          rescue
            puts "======== File Generated Error: Code generated could not be reparsed, parsing skiped =========="
          end
          begin
            #puts file_content
            write_file file, file_content
          rescue
            puts "======== Can't write the new file =========="
          end
        end
      end
    end
    
    modify_views en_yml
    
  end

end
