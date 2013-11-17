class CuratorLevel < ActiveRecord::Base

  has_many :users

  include Enumerated
  enumerated :label, [ 'Master Curator', 'Full Curator', 'Assistant Curator' ]

  class << self
    alias :master :master_curator
    alias :full :full_curator
    alias :assistant :assistant_curator
  end

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

  def translated_label
    I18n.t("curator_level_#{label.gsub(' ', '_').downcase}")
  end

end
