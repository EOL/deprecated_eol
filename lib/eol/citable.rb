module EOL
  class Citable
    attr_accessor :type
    attr_accessor :display_string
    attr_accessor :link_to_url
    attr_accessor :logo_cache_url
    attr_accessor :logo_path
    attr_accessor :agent_id
    attr_accessor :user
    
    def initialize(attrs={})
      default = { :type => nil, :display_string => nil, :link_to_url => nil,
                  :logo_cache_url => nil, :user => nil, :agent_id => nil, :logo_path => nil }
      default.merge(attrs).each do |a, v|
        self.instance_variable_set("@#{a}", v)
      end
    end
  end
end