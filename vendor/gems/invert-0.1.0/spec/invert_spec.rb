require File.join(File.dirname(__FILE__), "spec_helper")

describe "#{klass = Invert}" do
  describe "#new" do
    it "requires an argument" do
      Proc.new do
        klass.new
      end.should raise_error ArgumentError

      Proc.new do
        klass.new(10)
      end.should_not raise_error
    end
  end

  it "generally works" do
    [1, 2, 3].sort_by {|i| Invert.new(i)}.should == [3, 2, 1]
    ["alfa", "bravo", "charlie"].sort_by {|s| Invert.new(s)}.should == ["charlie", "bravo", "alfa"]
  end
end

describe "Invert()" do
  it "generally works" do
    [1, 2, 3].sort_by {|i| Invert.new(i)}.should == [3, 2, 1]
    ["alfa", "bravo", "charlie"].sort_by {|s| Invert.new(s)}.should == ["charlie", "bravo", "alfa"]
  end
end