class CuratorLevel < ActiveRecord::Base
  has_many :users

  include NamedDefaults

  set_defaults :label,
    [{method_name: :master, label: 'Master Curator'},
     {method_name: :assistant, label: 'Assistant Curator'},
     {method_name: :full, label: 'Full Curator'}
    ]

  def translated_label
    I18n.t("curator_level_#{label.gsub(' ', '_').downcase}")
  end

end
