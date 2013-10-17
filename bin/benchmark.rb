n = 1000

all_data = DataObject.all.compact

all_languages = Language.all

Benchmark.bm do |x|

  x.report("All vetted labels") do
    n.times do
      all_languages.each do |l|
        I18n.locale = l.iso_639_1
        all_data.each do |d|
          d.vetted && d.vetted.label
        end
      end
    end
  end

end
