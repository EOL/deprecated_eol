$:.unshift File.dirname(__FILE__)

module IndifferentVariableHash
  attr_accessor :variables

  def variables
    @variables ||= IndifferentVariableHash::Hash.new
  end

  def method_missing name, *args
    begin
      self.variables.send name, *args
    rescue Exception => ex
      super
    end
  end

  # IndifferentVariableHash::Hash extends Hash to be 'indifferent'
  #
  # 'Indifferent' has a few different meanings and needs to be better defined.
  #
  # This is custom in 2 major ways:
  #  * All keys will be stringified (so foo[:hi] and foo['hi'] are the same)
  #  * Sending messages are translated into keys, eg. foo.hi returns foo['hi']
  #
  class Hash < ::Hash

    def []= key, value
      super key.to_s, value
    end

    def [] key
      super key.to_s
    end

    def method_missing name, *args
      if name.to_s =~ /=$/ # eg. @hash.foo = 'bar'
        self[$`.to_s] = args.first
      else
        if args.empty?
          self[name.to_s] # eg. @hash.foo
        else
          super # anything else ... fall back to super
        end
      end
    end
  end

end

