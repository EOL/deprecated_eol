namespace :eol do
  desc "Port translations from db to yml"
  task :port_translations => :environment do
    pl = EOL.pluck_fields([:id, :iso_639_1],
      Language.where("iso_639_1 IS NOT NULL AND iso_639_1 != ''"))
    languages = Hash[*(pl.flat_map { |row| row.split(",", 2) })]
    results = {}
    something.each do |klass|
      # klass = Audience
      tk = Kernel.const_get("Translated#{klass.name}")
      tk.all.each do |instance|
        hash = instance.attributes
        language_id = hash.delete("language_id")
        ids = hash.keys.grep(/id$/)
        ids.each do |key|
          hash.delete(key)
        end
        lang = languages[language_id.to_s]
        results[lang] ||= []
        results[lang] << hash
        # YOU WERE HERE. SOOOO.... we have to decide how to store these. I think
        # we need to get all of the results from the table first, then look up
        # the english ones, and store THOSE, so you'll get something like
        # en:
        #   audience_label:
        #     children: "Children"
        # fr:
        #   audience_label:
        #     children: "weewees"

        # Note that we have to manually handle/add the phonetic stuff. ...I
        # think it only matters for Chinese, though, so perhaps we should only
        # use it there. Honestly, I don't see where phonetic_label is EVER used.
        # ...we might not have finished it. TODO: look through the DB when you
        # have a list of classes.
      end
    end
  end
end
