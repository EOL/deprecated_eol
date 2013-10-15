# encoding: utf-8
class CreateDefaultsAndAddChinese < ActiveRecord::Migration
  def up
    ChangeableObjectType.create_defaults
    Activity.create_defaults
    Language.create(iso_639_1: 'zh-Hant', iso_639_2: 'zh-Hant', iso_639_3: 'zh-Hant', source_form: '繁體字', sort_order: 1,
                    activated_on: Time.now.utc, language_group_id: 1)
  end

  def down
    # Nothing to do.
  end
end
