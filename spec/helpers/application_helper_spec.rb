require "spec_helper"

describe ApplicationHelper do

  before(:all) do
    load_foundation_cache
  end

  describe ApplicationHelper::EolFormBuilder do
    let(:helper) { ActionView::Base.new }
    let(:user)  { User.create(password: '') }
    let(:builder) { ApplicationHelper::EolFormBuilder.new :user, user, helper, {}, nil }
    it 'show have no allowed html help tips' do
      expect(builder.allowed_html_help_tip).to eq(nil)
    end
    it 'includes errors in field HTML' do
      expect(builder.label('username')).to have_selector('label[title~="There is a validation error on this element"]')
      expect(builder.label('username')).to have_selector('span.errors', text: 'can\'t be blank, is too short (minimum is 4 characters)')
    end
    it 'includes errors in field HTML when a block is given' do
      expect(builder.label('username'){ |l| }).to have_selector('label[title~="There is a validation error on this element"]')
      expect(builder.label('username'){ |l| }).to have_selector('span.errors', text: 'can\'t be blank, is too short (minimum is 4 characters)')
    end
  end
end
