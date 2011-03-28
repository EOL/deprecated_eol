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

end
