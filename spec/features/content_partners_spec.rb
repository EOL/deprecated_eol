# EXEMPLAR - Feature Spec (for testing the full stack)
#
# You should:
#
# * Avoid using mocks and stubs (except WebMock).
# * Test all the basic CRUD workflows.
# * DEFINITELY test a "render" as part of the Read.
# * Test any resource-specific edge-cases (though this is lower priority).
# * MINIMIZE your feature specs! These are expensive.
# * NOTE any exceptions.
#
# NOTE that we are not testing for simple "is here" or "is not here", as those
# types of tests belong in a view spec.
#
# NOTE There is no spec for destroying or deleting a CP, because we don't
# allow it.

describe '/content_partners' do

  before(:all) do
    SpecialCollection.create_enumerated
    ContentPartnerStatus.create_enumerated
  end

  # This is as close as we get to a "read" spec, here, because specifics
  # belong in a view spec, but having a feature spec ensure that the full
  # stack renders is actually useful.
  it 'renders' do
    visit content_partners_path
    expect(page.body).to have_content('Content Partners')
  end

  context 'when logged in as a user without content partners' do
    let(:user) { User.gen }

    it 'creates content_partner, signs agreement' do
      login_as user
      visit user_content_partners_path(user)
      click_button "Add new content partner"
      fill_in "Project name", with: "Something Interesting"
      fill_in "Project description", with: "Described this way"
      click_button "Create content partner"
      cp = user.reload.content_partners.first
      expect(cp).to_not be_nil
      expect(cp.name).to eq("Something Interesting")
      expect(cp.description).to eq("Described this way")
      expect(page.body).to have_content("Content partner agreement")
      fill_in "Signed by", with: user.full_name
      click_button "Agree to content partner terms"
      expect(cp.reload.agreement).to_not be_nil
      expect(cp.agreement.is_accepted?).to be true
      expect(page.body).to have_content("Add a new resource")
    end

  end

  context 'when logged in as a CP with no resources' do

    let(:user) { User.gen }
    let(:content_partner) do
      cp = ContentPartner.gen(user: user)
      ContentPartnerAgreement.gen(content_partner: cp, signed_on_date: 1.day.ago)
      cp
    end

    it 'alows editing of description' do
      login_as user
      visit content_partner_path(content_partner)
      click_link "Edit content partner"
      fill_in "Project description", with: "Edited description"
      click_button "Save content partner information"
      expect(content_partner.reload.description).to eq("Edited description")
      expect(page.body).to have_content("Add a new resource")
    end

  end

end
