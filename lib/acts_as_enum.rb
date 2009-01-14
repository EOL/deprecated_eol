require 'activerecord'

module ActsAsEnum

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def acts_as_enum # only add certain methods if a class acts_as_enum
      # has_many and whatnot are in this scope
      include ActsAsEnum::InstanceMethods
      extend  ActsAsEnum::SingletonMethods
    end
  end

  # good place for finder methods and whatnot
  module SingletonMethods

    # a version of find_by_label that'll cache objects
    def find_by_label_cached label
      @cached ||= {}
      @cached[label] ||= self.find_by_label(label)
      @cached[label]
    end

    # when we hit #all, go ahead and cache the individual instances
    def all *args
      instances = super *args
      @cached ||= {}
      instances.each {|instance| @cached[instance.label] ||= instance }
      instances
    end

    def [] *labels
      labels = labels.map(&:to_s).uniq.compact
      case labels.length
      when 0
        []
      when 1
        find_by_label_cached labels.first
      else
        # this one is *unordered* ... although it means 1 query per argument, i want ordered for now ...
        # find :all, :conditions => [labels.map {|l| "label = ?" }.join(' OR '), *labels]

        # this one is super unoptimized, but it returns things in the right order
        labels.inject([]){|all, label| all << find_by_label_cached(label); all }
      end
    end
  end

  # instance methods (duh)
  module InstanceMethods
    def to_s
      label
    end
  end

end

ActiveRecord::Base.send(:include, ActsAsEnum)
