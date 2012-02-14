require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationController do

  before(:all) do
    Language.gen_if_not_exists(:label => 'English')
    @taxon_name          = "<i>italic</i> foo & bar"
    @taxon_name_with_amp = "<i>italic</i> foo &amp; bar"
    @taxon_name_no_tags  = "italic foo & bar"
    @taxon_name_no_html  = "&lt;i&gt;italic&lt;/i&gt; foo &amp; bar"
  end

  it 'should have hh' do
    @controller.view_helper_methods.send(:hh, @taxon_name).should == @taxon_name_with_amp
  end

  it "should define controller action scope for translations" do
    @controller.send(:controller_action_scope).should be_a(Array)
  end

  it "should define generic parameters for translations" do
    @controller.send(:scoped_variables_for_translations).should be_a(Hash)
  end

  it "should define default meta data values" do
    @controller.send(:meta_data).should be_a(Hash)
  end

  it "should define default open graph tag values" do
    @controller.send(:meta_open_graph_data).should be_a(Hash)
  end

  it "should define default tweet data values" do
    @controller.send(:tweet_data).should be_a(Hash)
  end

  it "should store a copy of the original unmodified request params" do
    @controller.send(:original_request_params).should be_a(Hash)
  end

end
