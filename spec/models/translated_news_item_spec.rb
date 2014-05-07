require "spec_helper"

describe TranslatedNewsItem do

  before(:all) do
    Language.create_english
  end

  let(:user) { build_stubbed(User) }
  let(:language) { Language.english }

  describe '#can_be_read_by' do

    subject { TranslatedNewsItem.new }

    it 'true for admins' do
      allow(user).to receive(:is_admin?) { true }
      expect(subject.can_be_read_by?(user)).to be_true
    end

    # Honestly, I don't even know when this is set. :|
    it 'true for active_translation' do
      allow(subject).to receive(:active_translation?) { true }
      expect(subject.can_be_read_by?(user)).to be_true
    end

    it 'false for normal users' do
      expect(subject.can_be_read_by?(user)).to_not be_true
    end

  end

  describe '#title_with_language' do

    subject { TranslatedNewsItem.new(title: "Titled",
                                     language: language).title_with_language }

    it { should eq("Titled (#{language.iso_code})") } 

  end

end
