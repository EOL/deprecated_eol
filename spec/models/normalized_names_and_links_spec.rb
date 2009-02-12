require File.dirname(__FILE__) + '/../spec_helper'

#
# these specs might me too DRY ... looping through @examples makes these 
# a bit hard to follow ... might want to unDRY this spec a bit to be easier to read
#
# basically, @examples has strings (like a Name#string might be) and we 
# parse them into name_parts and generate NormalizedNames and link them 
# back to the original Name thru NormalizedLinks ... we test that here!
#
describe "Name Normalization" do

  before do
    # for each of the                     they should all be parsed into
    # strings on the left                 the parts on the right
    @examples = {
      'Why Hello There'                     => ['Why', 'Hello', 'There'],
      '{"W..~h..y}`_ [He"%llo] =-+T$he;re#' => ['Why', 'Hello', 'There'],
      '*Why and Hello and There!'           => ['Why', 'Hello', 'There']
    }
    @number_of_name_parts_in_examples = 3 # 'Why', 'Hello', & 'There'
  end

  describe NormalizedName do

    it "should be able to parse a Name or String into multiple name_parts" do
      lambda {

        @examples.each do |name_string, name_parts|
          NormalizedName.parse_into_parts(name_string).should == name_parts

          # confirm that a Name works too, not just Strings
          name = Name.gen :string => name_string
          NormalizedName.parse_into_parts(name).should == name_parts
        end

      }.should_not change(NormalizedName, :count) # parse_into_parts is readonly
    end

    it "should be able to parse! a Name into multiple NormalizedNames" do
      lambda {

        @examples.each do |name_string, name_parts|
          name = Name.gen :string => name_string
          normalized_names = NormalizedName.parse! name
          normalized_names.length.should == @number_of_name_parts_in_examples
          normalized_names.map(&:name_part).should == name_parts
        end

      }.should change(NormalizedName, :count).by(@number_of_name_parts_in_examples) # parse! actually creates NormalizedNames
    end

  end

  describe NormalizedLink do

    it "should be able to parse! Name into NormalizedLinks (and their NormalizedNames)" do
      lambda {

        @examples.each do |name_string, name_parts|
          name  = Name.gen :string => name_string
          links = NormalizedLink.parse! name
          links.length.should == @number_of_name_parts_in_examples
          links.each do |link|
            link.name.id.should == name.id # confirm that the generated links all point to the right Name
            name_parts.should include(link.normalized_name.name_part) # the generated name_part should be Why or Hello or There
          end
        end

      }.should change(NormalizedLink, :count).by(@number_of_name_parts_in_examples * @examples.length) 
      # parse! creates NormalizedNames and NormalizedLinks ... we create links for all name_parts for *EACH* example
    end

  end

end
