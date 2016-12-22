#encoding: utf-8
class AdditionalNewLanguagesToCommonNames < ActiveRecord::Migration
  def up
    Language.create_english # Ensure that we have our default language before inserting any...
    unless Language.exists?(iso_639_1: 'dy')
      l = Language.create(iso_639_1: "dy", iso_639_2: "dyo", iso_639_3: "dyo", source_form: "Jola-Fonyi", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Jola-Fonyi')
    end
    # has same Iso code already used
    unless Language.exists?(iso_639_1: 'sf')
      l = Language.create(iso_639_1: "sf", iso_639_2: "aff", iso_639_3: "aff", source_form: "Saint Lucian French Creole", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Saint Lucian French Creole')
    end

    unless Language.exists?(iso_639_1: 'lr')
      l = Language.create(iso_639_1: "lr", iso_639_2: "lir", iso_639_3: "lir", source_form: "Liberian English", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Liberian English')
    end

    unless Language.exists?(iso_639_1: 'dw')
      l = Language.create(iso_639_1: "dw", iso_639_2: "dee", iso_639_3: "dee", source_form: "Dē/Dewoin", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Dē/Dewoin')
    end

    unless Language.exists?(iso_639_1: 'bq')
      l = Language.create(iso_639_1: "bq", iso_639_2: "bsq", iso_639_3: "bsq", source_form: "Bassa", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Bassa')
    end

    unless Language.exists?(iso_639_1: 'rk')
      l = Language.create(iso_639_1: "rk", iso_639_2: "kro", iso_639_3: "kro", source_form: "Kru", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Kru')
    end

    unless Language.exists?(iso_639_1: 'gr')
      l = Language.create(iso_639_1: "gr", iso_639_2: "grb", iso_639_3: "grb", source_form: "Grebo", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Grebo')
    end

    unless Language.exists?(iso_639_1: 'dn')
      l = Language.create(iso_639_1: "dn", iso_639_2: "dmn", iso_639_3: "dmn", source_form: "Mande", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Mande')
    end

    unless Language.exists?(iso_639_1: 'ma')
      l = Language.create(iso_639_1: "ma", iso_639_2: "man", iso_639_3: "man", source_form: "Mandigo", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Mandigo')
    end

    unless Language.exists?(iso_639_1: 'va')
      l = Language.create(iso_639_1: "va", iso_639_2: "vai", iso_639_3: "vai", source_form: "Vai", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Vai')
    end

    unless Language.exists?(iso_639_1: 'go')
      l = Language.create(iso_639_1: "go", iso_639_2: "gol", iso_639_3: "gol", source_form: "Gola", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Gola')
    end

     unless Language.exists?(iso_639_1: 'by')
      l = Language.create(iso_639_1: "by", iso_639_2: "buy", iso_639_3: "buy", source_form: "Bulom So", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Bulom So')
    end

     unless Language.exists?(iso_639_1: 'df')
      l = Language.create(iso_639_1: "df", iso_639_2: "daf", iso_639_3: "daf", source_form: "Gio/Dan", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Gio/Dan')
    end

     unless Language.exists?(iso_639_1: 'kh')
      l = Language.create(iso_639_1: "kh", iso_639_2: "krw", iso_639_3: "krw", source_form: "Krahn, Western", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Krahn, Western')
    end

     unless Language.exists?(iso_639_1: 'mv')
      l = Language.create(iso_639_1: "mv", iso_639_2: "mev", iso_639_3: "mev", source_form: "Mano", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Mano')
    end
  end

  def down
     # Nothing to do.
  end
end
