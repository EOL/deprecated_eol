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
          if !line.empty?            
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
