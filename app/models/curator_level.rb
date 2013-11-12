class CuratorLevel < ActiveRecord::Base
  has_many :users

  include EnumDefaults

  set_defaults :label,
    ['Master Curator', 'Assistant Curator', 'Full Curator']

  class << self
    alias :master :master_curator
    alias :full :full_curator
    alias :assistant :assistant_curator
  end

  def translated_label
    I18n.t("curator_level_#{label.gsub(' ', '_').downcase}")
  end

end
