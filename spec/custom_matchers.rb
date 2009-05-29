require 'rspec-custom-matchers'

# a place for us to define our custom matchers
#
# do you want a custom matcher that has prettier 
# and smarter failure messages?  if so, you can 
# make full blown matchers *or* i recommend 
# checking our Spec::Matchers.create.  this is 
# either built into RSpec or is added by Merb.
# eg: http://github.com/wycats/merb/blob/84f61f3976193e38d45e5288609c8056c8e1a56f/merb-core/lib/merb-core/test/matchers/request_matchers.rb
#
module EOL::Spec::Matchers
  extend CustomMatcher::Helper

  matcher(:be_a_curator_of) {|user, clade| user.can_curate? clade }

  matcher(:include) {|array, block| array.include? block }

  # We're only using this for testing Attributions, but it does DRY things up and make it much more readable:
  class FindAfterAgentRole
    def initialize(agent, role)
      @agent = agent
      @role  = role
    end
    def matches?(target)
      @target = target
      @target.each_with_index do |attribution, i|
        if attribution.agent == @agent
          return false if i == 0 # Because it should NOT be found at the beginning of the array!
          return @target[i-1].agent_role == @role
        end
      end
    end
    def failure_message
      "expected Agent for \"#{@agent.project_name}\" to come after \"#{@role.label}\" in [" <<
      "#{@target.map {|ado| "#{ado.agent_role} Agent \"#{ado.agent.project_name}\"" }.join(', ')}]"
    end
    def negative_failure_message
      "expected Agent for \"#{@agent.project_name}\" NOT to come after \"#{@role.label}\" in [" <<
      "#{@target.map {|ado| "#{ado.agent_role} Agent \"#{ado.agent.project_name}\"" }.join(', ')}]"
    end
  end

  def find_after_agent_role(agent, role)
    FindAfterAgentRole.new(agent, role)
  end

  class OnlyInclude
    def initialize(fields)
      @expected_fields = fields
    end
    
    def matches?(array)
      @array = array
      @array.sort == @expected_fields.sort
    end
    
    def description
      "only include"
    end
    
    def failure_message
      if @expected_fields.length != @array.length
        "expected to have #{@expected_fields.length} entries, but had #{@array.length}: #{@array.inspect}"
      else
        "expected #{@array.inspect} to include #{(@expected_fields - @array).inspect}"
      end
    end
    
    def negative_failure_message
      " #{@array.inspect} expected to include other entries"
    end
  end

  def only_include(*args)
    OnlyInclude.new args
  end

end
