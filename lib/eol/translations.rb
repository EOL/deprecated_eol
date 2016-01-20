module EOL
  module Translations

    # currently this must run in development or test mode to see the translation tables
    def self.make_list_of_translated_tables
      all_translated_models = {}

      # check all models in the first level of app/models
      Dir.foreach(Rails.root.join('app', 'models')) do |model_path|
        if m = model_path.match(/^(([a-z]+_)*[a-z]+)\.rb$/)
          model_name = m[1]
          begin
            klass = model_name.camelcase.constantize
            if defined?(klass::USES_TRANSLATIONS)
              translated_fields = []

              klass::TRANSLATION_CLASS.column_names.each do |cn|
                unless ['id', 'language_id', klass.reflections[:translations].primary_key_name].include?(cn) || cn.match(/^phonetic_*/)
                  translated_fields << cn.to_sym
                end
              end
              all_translated_models[klass.to_s.to_sym] = translated_fields.clone
            end
          rescue
          end
        end
      end

      # outputting the final hash of models and their translated attributes
      pp all_translated_models
    end

    # this needs a V1 database and will pull out only the English (default) labels for translating
    def self.create_spreadsheet_of_translated_fields
      translated_models = {:Visibility=>[:label],
                           :TocItem=>[:label],
                           :InfoItem=>[:label],
                           :AgentDataType=>[:label],
                           :Activity=>[:name],
                           :SynonymRelation=>[:label],
                           :Status=>[:label],
                           :ResourceAgentRole=>[:label],
                           :CollectionType=>[:label],
                           :Rank=>[:label],
                           :AgentContactRole=>[:label],
                           :ResourceStatus=>[:label],
                           :MimeType=>[:label],
                           :AgentRole=>[:label],
                           :UntrustReason=>[:label],
                           :DataType=>[:label],
                           :Language=>[:label],
                           :ContactSubject=>[:title],
                           # :NewsItem=>[:body, :title],
                           :AgentStatus=>[:label],
                           :Vetted=>[:label],
                           :ServiceType=>[:label],
                           :License=>[:description],
                           :Audience=>[:label]}

      dump_path = Rails.root.join('tmp', 'database_translations.tab')
      File.open(dump_path, 'w') do |f|
        f.write("Class Name\tID\tField\tValue\n")
        translated_models.each do |m, fields|
          klass = m.to_s.constantize
          klass.find_each do |i|
            i.attributes.each do |a, v|
              if fields.include?(a.to_sym)
                f.write("#{klass.to_s}\t#{i.id}\t#{a}\t#{v}\n")
              end
            end
          end
        end
      end
    end

  end
end
