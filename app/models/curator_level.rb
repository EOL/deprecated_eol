class CuratorLevel < ActiveRecord::Base
  has_many :users

  def self.create_defaults
    if !self.master_curator
      CuratorLevel.create(:label => 'Master Curator')
    end
    if !self.assistant_curator
      CuratorLevel.create(:label => 'Assistant Curator')
    end
    if !self.full_curator
      CuratorLevel.create(:label => 'Full Curator')
    end
  end

  def self.master_curator
    cached_find(:label, 'Master Curator')
  end

  def self.full_curator
    cached_find(:label, 'Full Curator')
  end

  def self.assistant_curator
    cached_find(:label, 'Assistant Curator')
  end

  def translated_label
    I18n.t("curator_level_#{label.gsub(' ', '_').downcase}")
  end

end