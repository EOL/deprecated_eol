module ActiveRecord
  class Base
    private
    def self.define_core_relationships(options = {})
      # there is already a core_relationships association for whatever reason
      if self.reflections[:core_relationships]
        raise 'Cannot re-define core_relationships'
      end
      has_one :core_relationships, :foreign_key => :id, :class_name => self.class_name, :include => options[:include], :select => options[:select]
      
      # in case we remove some here - further instance of this object would default to having that association
      # removed from their details methods
      named_scope :core_relationships, Proc.new { |*my_options|
        # create a new array of options for each named_scope call
        named_scope_options = options.deepcopy
        
        if my_options[0] && my_options[0].class == Hash
          proc_options = my_options[0]
          
          named_scope_options[:select] = proc_options[:select] || named_scope_options[:select]
          named_scope_options[:include] = proc_options[:include] || named_scope_options[:include]
          # turn :include into an array if its nil, a string or a symbol
          if named_scope_options[:include].class != Hash && named_scope_options[:include].class != Array
            named_scope_options[:include] = [named_scope_options[:include]].compact
          end
          
          if !proc_options[:only].blank?
            if proc_options[:only].class == Symbol
              named_scope_options[:include] = [proc_options[:only]]
            else #array
              named_scope_options[:include] = proc_options[:only]
            end
          else
            # default :include associations can be excluded
            if !proc_options[:except].blank?
              named_scope_options[:include].remove_element!(proc_options[:except])
            end
            
            # assocations can be added to the default :include
            if !proc_options[:add_include].blank?
              named_scope_options[:include].add_element!(proc_options[:add_include])
            end
              
            # asked to add a series of associations but not any includes
            if proc_options[:add_select].blank? && !proc_options[:add_include].blank?
              proc_options[:add_select] = self.default_association_select(proc_options[:add_include])
            end
            
            if !proc_options[:add_select].blank?
              if named_scope_options[:select].blank?
                named_scope_options[:select] = select_statement_to_string(proc_options[:add_select])
              elsif named_scope_options[:select].class == Hash
                named_scope_options[:select] = select_statement_to_string(named_scope_options[:select]) + ", " + select_statement_to_string(proc_options[:add_select])
              else
                named_scope_options[:select][0] = ", " + select_statement_to_string(proc_options[:add_select])
              end
            end
          end
        end
        
        # return the possibly modified set of parameters
        named_scope_options
      }
    end
    
    def self.default_association_select(includes)
      if includes.class == Symbol
        table = self.reflections[includes].klass.table_name
        return "#{table}.*"
      elsif includes.class == Array
        selects = []
        includes.each do |inc|
          selects << self.default_association_select(inc)
        end
        return selects.join(",")
      elsif includes.class == Hash
        selects = []
        includes.each do |k, v|
          reflection_klass = self.reflections[k].klass
          selects << reflection_klass.default_association_select(v)
        end
        return selects.join(",")
      end
    end
  end
end

class Array
  # this method will remove from an array an element
  # [:a, :b].remove_element!(:a)                        => [:b]
  # [:a, {:b => :c}].remove_element!(:b)                => [:a]
  # [:a, {:b => :c}].remove_element!({:b => :c})        => [:a]
  # [:a, {:b => [:c, :d]}].remove_element!({:b => :c})  => [:a, {:b => :d}]
  def remove_element!(element)
    # element is an array, so recursively remove the contents
    if element.class == Array
      element.each do |k|
        self.remove_element!(k)
      end
    
    # element is a single value, so remove it if it is the value, or key of a hash
    elsif element.class == Symbol || element.class == String
      element = element.to_sym
      self.each_with_index do |v, index|
        if v.class == Hash
          self[index] = v.remove_element!(element)
        else
          self[index] = nil if v.to_sym == element
        end
      end
    
    # element is a hash, so remove the matching values
    elsif element.class == Hash
      self.each_with_index do |v, index|
        if v.class == Hash
          self[index] = v.remove_element!(element)
        end
      end
    end
    self.delete_if{|v| v.blank?}
  end
  
  def add_element!(element)
    # element is an array, so recursively add the contents
    if element.class == Array
      element.each do |k|
        self.add_element!(k)
      end
    
    # element is a single value, so add it if it doesn't already exist
    elsif element.class == Symbol || element.class == String
      element = element.to_sym
      in_array = false
      self.each_with_index do |v, index|
        if v.class == Hash
          in_array = true unless v.keys.select{|k| k.to_sym == element}.blank?
        else
          in_array = true if v.to_sym == element
        end
      end
      unless in_array
        self << element
      end
    
    # element is a hash, so remove the matching values
    elsif element.class == Hash
      element.each do |el_k, el_v|
        in_array = false
        el_k = el_k.to_sym
        self.each_with_index do |my_v, index|
          if my_v.class == Hash
            my_v.each do |v_k, v_v|
              if v_k.to_sym == el_k
                if v_v != Array
                  new_v_v = [v_v].add_element!(el_v)
                else
                  new_v_v = v_v.add_element!(el_v)
                end
                new_v_v = new_v_v[0] if new_v_v.length == 1
                self[index] = {v_k => new_v_v}
                in_array = true
              end
            end
            
            # unless my_v.keys.select{|k| k.to_sym == el_k}.blank?
            #   my_v = [my_v] if my_v != Array
            #   self[index] = my_v.add_element!(el_v)
            # end
          else
            if my_v.to_sym == el_k
              self[index] = {el_k => el_v}
              in_array = true
            end
          end
        end
        unless in_array
          self << element
        end
      end
    end
    self
  end
end

class Hash
  # this method will remove from a hash an element
  # {:a => :b, :c => :d}.remove_element!(:b)          => {:a => :b}
  # {:a => :b, :c => :d}.remove_element!({:c => :d})  => {:a => :b}
  # {:b => [:c, :d]}.remove_element!({:b => :c})      => {:b => :d}
  def remove_element!(element)
    # element is an array, so recursively remove the contents
    if element.class == Array
      element.each do |k|
        self.remove_element!(k)
      end
    
    # element is a single value, so remove it
    elsif element.class == Symbol || element.class == String
      element = element.to_sym
      self.reject! do |k, v|
        k.to_sym == element
      end
    
    # element is a hash, so remove the matching values
    elsif element.class == Hash
      element.each do |el_k, el_v|
        self.each do |my_k, my_v|
          if my_k.to_sym == el_k.to_sym
            if (my_v.class == Symbol || my_v.class == String) && (el_v.class == Symbol || el_v.class == String)
              self[my_k] = nil if my_v.to_sym == el_v.to_sym
            else
              self[my_k] = my_v.remove_element!(el_v)
            end
          end
        end
      end
    end
    self.delete_if{|k,v| v.blank?}
  end
end
