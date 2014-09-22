# encoding: utf-8

# EXEMPLAR

describe "/content_partners" do
  before(:all) do
    populate_tables(:data_types, :special_collection, :content_partner_statuses,
                    :licenses)
  end

  context "when not logged" do
    let(:content_partner) { create(:content_partner) }

    it "renders index" do
      visit content_partners_path
      expect(page.body).to have_content("Content Partners")
    end

    it "renders show" do
      visit content_partner_path(content_partner)
      expect(page.body).to have_content(content_partner.name)
    end

    it "renders new" do
      visit new_content_partner_path
      expect(page.current_path).to eq login_path
    end

    it "renders edit" do
      visit edit_content_partner_path(content_partner)
      expect(page.current_path).to eq login_path
    end
  end

  context "when logged" do
    before(:each) do
      login_as user
    end

    let(:content_partner) { create(:content_partner) }
    let(:user) { User.gen }

    it "renders index" do
      visit content_partners_path
      expect(page.body).to have_content("Content Partners")
    end

    it "renders show" do
      visit content_partner_path(content_partner)
      expect(page.body).to have_content(content_partner.name)
    end

    it "renders new" do
      visit new_content_partner_path
      expect(page.current_path).to eq new_content_partner_path
    end

    it "renders edit" do
      visit edit_content_partner_path(content_partner)
      expect(page.current_path).
        to_not eq edit_content_partner_path(content_partner)
      expect(page.body).to have_content("Access denied")
    end

    it "creates content_partner, signs agreement" do
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

    it "does not create partner with a problem" do
      visit user_content_partners_path(user)
      click_button "Add new content partner"
      fill_in "Project description", with: "Described this way"
      click_button "Create content partner"
      cp = user.reload.content_partners.first
      expect(cp).to be_nil
      expect(page.body).to_not have_content("Content partner agreement")
      expect(page.body).
        to have_content("partner details were not updated")
    end

    context "has content_partner" do
      let(:content_partner) do
        cp = ContentPartner.gen(user: user)
        ContentPartnerAgreement.gen(content_partner: cp,
                                    signed_on_date: 1.day.ago)
        cp
      end

      it "renders edit" do
        visit edit_content_partner_path(content_partner)
        expect(page.current_path).
          to eq edit_content_partner_path(content_partner)
        expect(page.body).to_not have_content("Access denied")
        expect(page.body).to have_content("Content partner profile information")
      end

      context "no resources" do
        it "edits, updates, goes to add resource" do
          visit content_partner_path(content_partner)
          click_link "Edit content partner"
          fill_in "Project description", with: "Edited description"
          click_button "Save content partner information"
          expect(content_partner.reload.description).to eq("Edited description")
          expect(page.body).to have_content("Add a new resource")
        end
      end

      context "with resources" do
        let!(:resource) do
          rs = Resource.gen(content_partner: content_partner)
          rs
        end

        it "updates and redirects to content_partner list" do
          expect(user.content_partners.first.resources.size).to be > 0
          visit content_partner_path(content_partner)
          click_link "Edit content partner"
          fill_in "Project description", with: "Edited description"
          click_button "Save content partner information"
          expect(content_partner.reload.description).to eq("Edited description")
          expect(page.body).to_not have_content("Add a new resource")
        end
      end

    end
  end
end
