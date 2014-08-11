require "spec_helper"

describe '/content_partners' do

  it 'renders' do
    visit content_partners_path
    expect(page.body).to have_content('Content Partners')
  end
  
  context 'creates new' do
    let(:user) { User.gen }

    it 'creates content_partner' do
      require 'ruby-debug'; debugger
      login_as user

      visit "/users/#{user.id}/content_partners"
    end
  end
end
