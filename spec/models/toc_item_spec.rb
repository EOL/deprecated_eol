require File.dirname(__FILE__) + '/../spec_helper'

describe TocItem do
  it 'should allow user submitted text' do
    toc_item = TocItem.gen(:info_items => [InfoItem.gen])
    toc_item.allow_user_text?.should be_true
  end

  it 'should not allow user submitted text' do
    toc_item = TocItem.gen
    toc_item.allow_user_text?.should be_false
  end
end
