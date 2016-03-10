class AddNewLanguagesToCommonNames < ActiveRecord::Migration
  def up
    Language.create_english # Ensure that we have our default language before inserting any...
    unless Language.exists?(iso_639_1: 'bm')
      l = Language.create(iso_639_1: "bm", iso_639_2: "bam", iso_639_3: "bam", source_form: "bamanankan", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Bambara')
    end
    unless Language.exists?(iso_639_1: 'pu')
      l = Language.create(iso_639_1: "pu", iso_639_2: "fuf", iso_639_3: "fuf", source_form: "Pular", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Pular')
    end
    unless Language.exists?(iso_639_1: 'pf')
      l = Language.create(iso_639_1: "pf", iso_639_2: "fuf-FF", iso_639_3: "fuf-FF", source_form: "Pulla Fuuta", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Pulla Fuuta')
    end
    unless Language.exists?(iso_639_1: 'ff')
      l = Language.create(iso_639_1: "ff", iso_639_2: "fuk", iso_639_3: "fuk", source_form: "Fulakunda/Fulani", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Fulakunda/Fulani')
    end
    unless Language.exists?(iso_639_1: 'mn')
      l = Language.create(iso_639_1: "mn", iso_639_2: "mnk", iso_639_3: "mnk", source_form: "Mandinka", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Mandinka')
    end
    unless Language.exists?(iso_639_1: 'se')
      l = Language.create(iso_639_1: "se", iso_639_2: "srr", iso_639_3: "srr", source_form: "Sereer", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Sereer')
    end
    unless Language.exists?(iso_639_1: 'gf')
      l = Language.create(iso_639_1: "gf", iso_639_2: "gcl-FR", iso_639_3: "gcl-FR", source_form: "Grenadian French Creole", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Grenadian French Creole')
    end
    unless Language.exists?(iso_639_1: 'ge')
      l = Language.create(iso_639_1: "ge", iso_639_2: "gcl", iso_639_3: "gcl", source_form: "Grenadian English Creole", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'Grenadian English Creole')
    end
    unless Language.exists?(iso_639_1: 'ac')
      l = Language.create(iso_639_1: "ac", iso_639_2: "acf", iso_639_3: "acf", source_form: "St. Lucian Kweyol", sort_order: 1,
                          activated_on: Time.now)
      TranslatedLanguage.create(language_id: Language.default.id, original_language_id: l.id, label: 'St. Lucian Kweyol')
    end
  end

  def down
    # Nothing to do.
  end
end
