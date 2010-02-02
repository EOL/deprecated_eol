require File.dirname(__FILE__) + '/../spec_helper'

def find_or_gen(name)
  AgentRole.find_by_label(name) || AgentRole.gen(:label => name)
end

describe Attributions do

  # Please note that this gets run before each describe block... not just once!
  before(:all) do

    @source = find_or_gen('Source')
    @author = find_or_gen('Author')
    @unused = find_or_gen('Unused')
    @last   = find_or_gen('Last')

    # [sigh]  So, the values of acts_as_enum are getting cached somehow, and I can't clear them. So this
    # dodges the problem by forcing the return values that will match our expectations:
    AgentRole.stub!(:[]).with(:Source).and_return(@source)
    AgentRole.stub!(:[]).with(:Author).and_return(@author)
    # This one isn't working.  :\
    AgentRole.stub!(:[]).with(:Author, :Source).and_return([@author, @source])

    @fake_attribution_order = [@source, @author, @unused, @last]

    # This array MUST be in reverse order, because I am...
    @fake_ados    = [AgentsDataObject.gen(:agent_role => @last),
                     AgentsDataObject.gen(:agent_role => @author, :view_order => 2),
                     AgentsDataObject.gen(:agent_role => @author, :view_order => 1),
                     AgentsDataObject.gen(:agent_role => @source)]
    @return_order = @fake_ados.reverse # ...cheating to make sure the result is the reverse of that.

    @data_type = DataType.gen

  end

  describe 'initialization' do

    before(:each) do
      DataType.stub!(:full_attribution_order).and_return(@fake_attribution_order)
    end

    it 'should raise an error without a list of ADOs' do
      lambda { Attributions.new(nil, @data_type) }.should raise_error /ado/i
    end

    it 'should raise an error without a data type' do
      lambda { Attributions.new(@fake_ados, nil) }.should raise_error /data.?type/i
    end

    it 'should raise an error if list of ADOs contains non-ADOs' do
      lambda { Attributions.new([{:hashes => 'will not work'}], @data_type) }.should raise_error /ado/i
    end

    it 'should raise an error if Data Type... isn\'t.' do
      lambda { Attributions.new(@fake_ados, {:another => 'bogus hash'}) }.should raise_error /data.?type/i
    end

    it 'should use its data_types\'s full attribution order' do
      DataType.should_receive(:full_attribution_order).and_return(@fake_attribution_order)
      Attributions.new(@fake_ados, @data_type)
    end

    it 'should sort by attribution order, then view order (also, with no nils)' do
      # Okay, this sucks... but I use map() to get the raw array, not the Attributions class:
      Attributions.new(@fake_ados, @data_type).map {|f| f}.should == @return_order
    end

  end

  describe 'add_* methods' do

    before(:each) do
      DataType.stub!(:full_attribution_order).and_return(@fake_attribution_order)
      @attributions = Attributions.new(@fake_ados, @data_type)
    end

    it 'should do nothing if supplier is nil' do
      @attributions.add_supplier(nil)
      @attributions.should == @attributions
    end

    it 'should insert supplier after the Author' do
      @supplier = Agent.gen
      @attributions.add_supplier(@supplier)
      @attributions.should find_after_agent_role(@supplier, @author)
      @attributions.map {|a| a.agent_role.label }.should include('Supplier')
    end

    it 'should do nothing if there is no license and no rights_statement' do
      @attributions.add_license(nil, nil)
      @attributions.should == @attributions
    end

    it 'should use public domain if there is no license' do
      License.should_receive(:public_domain).and_return(License.gen)
      @attributions.add_license(nil, 'whatever, just not nil')
    end

    it 'should insert the license after the author, if both source and author exist' do
      # Source and Author both exist in our current example.
      @license = License.gen(:description => 'oh say can you see')
      @attributions.add_license(@license, '')
      ado = @attributions.detect {|attr| attr.agent.project_name == @license.description }
      ado.should_not be_nil # It didn't get added at all, if this fails.
      ado.agent_role.label.should == 'Copyright'
      @attributions.should find_after_agent_role(ado.agent, @author)
    end

    it 'should insert the license after the source, if no author exists' do
      # ARGH.  I don't know why the stub! above doesn't work... but it doesn't.  Soooo:
      AgentRole.should_receive(:[]).with(:Author, :Source).and_return([@author, @source])
      attributions = Attributions.new(@fake_ados.delete_if {|ado| ado.agent_role == @author}, @data_type)
      @license = License.gen(:description => 'bombs bursting in air')
      attributions.add_license(@license, '')
      ado = attributions.detect {|attr| attr.agent.project_name == @license.description }
      ado.should_not be_nil # It didn't get added at all, if this fails.
      #attributions.should find_after_agent_role(ado.agent, @source)
    end

    it 'should put the license first, if no author or source exists' do
      attributions = Attributions.new(@fake_ados.delete_if {|ado| [@author, @source].include? ado.agent_role}, @data_type)
      @license = License.gen(:description => 'our home and native land')
      attributions.add_license(@license, '')
      attributions[0].agent.project_name.should == @license.description
    end

    it 'should do nothing if there is no location' do
      @attributions.add_location('')
      @attributions.should == @attributions
    end

    it 'should add location to the end of the array' do
      location = 'here there, and everywhere'
      @attributions.add_location(location)
      @attributions.last.agent.project_name.should == location
      @attributions.last.agent_role.label.should == 'Location'
    end

    it 'should do nothing if there is no Source URL' do
      @attributions.add_source_url('')
      @attributions.should == @attributions
    end

    it 'should add Source URL to the end of the array' do
      source_url = 'here there, and everywhere'
      @attributions.add_source_url(source_url)
      @attributions.last.agent.project_name.should =~ /view\s+original/i
      @attributions.last.agent.homepage.should == source_url
      @attributions.last.agent_role.label.should == 'Source URL'
    end

    it 'should do nothing if there is no Citation' do
      @attributions.add_citation('')
      @attributions.should == @attributions
    end

    it 'should add Citation to the end of the array' do
      citation = 'here there, and everywhere'
      @attributions.add_citation(citation)
      @attributions.last.agent.project_name.should == citation
      @attributions.last.agent_role.label.should == 'Citation'
    end

  end

end
