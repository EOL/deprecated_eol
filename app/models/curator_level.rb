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

  class << self
    def master
      cached_find(:label, 'Master Curator')
    end
    alias :master_curator :master

    def full
      cached_find(:label, 'Full Curator')
    end
    alias :full_curator :full

    def assistant
      cached_find(:label, 'Assistant Curator')
    end
    alias :assistant_curator :assistant
  end

  def translated_label
    I18n.t("curator_level_#{label.gsub(' ', '_').downcase}")
  end

end
