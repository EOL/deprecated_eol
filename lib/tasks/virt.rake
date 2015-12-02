namespace :virt do
  desc '"Fix" old virtuoso data for scale and search'
  task :fix => :environment do
    TraitBank.fix_old_data
  end

  desc 'Add fake data to virtuoso.'
  task :add_fake_data => :environment do
    # Units:
    #========
    # http://purl.obolibrary.org/obo/UO_0000009 = kg
    # http://purl.obolibrary.org/obo/UO_0000021 = g
    #======================================================
    # statistical methods:
    #=====================
    # http://semanticscience.org/resource/SIO_001109 = mean
    # http://semanticscience.org/resource/SIO_001110 = median
    # http://semanticscience.org/resource/SIO_001111 = mode
    # http://eol.org/schema/terms/average = average
    # http://semanticscience.org/resource/SIO_001114 = max
    # http://semanticscience.org/resource/SIO_001113 = min
    # http://semanticscience.org/resource/SIO_000770 = standard deviation
    # http://purl.obolibrary.org/obo/OBI_0000235 = standard error
    # http://eol.org/schema/terms/SampleSize = sample size
    #======================================================
    # sex:
    #=====
    # http://eol.org/schema/terms/female
    # http://eol.org/schema/terms/male
    #===================================
    # life stage:
    #============
    # http://www.ebi.ac.uk/efo/EFO_0001272 = adult
    # http://purl.obolibrary.org/obo/PATO_0001185 = larval
    #=====================================================
    # measurement:
    # http://eol.org/schema/terms/weight
    EOL::Sparql.connection.delete_graph("http://eol.org/schema/resources/#{Resource.last.id}")
    statistical_methods_arr = ["http://semanticscience.org/resource/SIO_001109", "http://semanticscience.org/resource/SIO_001110", "http://semanticscience.org/resource/SIO_001111",
      "http://eol.org/schema/terms/average", "http://semanticscience.org/resource/SIO_001114", "http://semanticscience.org/resource/SIO_001113", "http://semanticscience.org/resource/SIO_000770",
      "http://purl.obolibrary.org/obo/OBI_0000235", "http://eol.org/schema/terms/SampleSize"]
    sex_arr = ["http://eol.org/schema/terms/female", "http://eol.org/schema/terms/male"]
    life_stage_arr = ["http://www.ebi.ac.uk/efo/EFO_0001272", "http://purl.obolibrary.org/obo/PATO_0001185"]

    statistical_methods_labels_arr = ["mean", "median", "mode", "average", "max", "min", "standard deviation", "standard error", "sample size"]
    sex_labels_arr = ["female", "male"]
    life_stage_labels_arr = ["adult", "larval"]

    # add known_uris for statistical methods
    count = 0
    statistical_methods_arr.each do |sm|
      k = KnownUri.gen
      TranslatedKnownUri.create(known_uri_id: k.id, name: statistical_methods_labels_arr[count], language_id: 1)   if k.update_attributes(uri:  sm, uri_type_id: UriType.value.id)
      count += 1
    end

    count = 0
    sex_arr.each do |s|
      k = KnownUri.gen
      TranslatedKnownUri.create(known_uri_id: k.id, name: sex_labels_arr[count], language_id: 1)   if k.update_attributes(uri:  s, uri_type_id: UriType.value.id)
      count += 1
    end

    count = 0
    life_stage_arr.each do |l|
      k = KnownUri.gen
      TranslatedKnownUri.create(known_uri_id: k.id, name: life_stage_labels_arr[count], language_id: 1)   if k.update_attributes(uri:  l, uri_type_id: UriType.value.id)
      count += 1
    end

    value = 2
    statistical_methods_arr.each do |sm|
      sex_arr.each do |s|
        life_stage_arr.each do |l|
          DataMeasurement.new(:predicate => "http://eol.org/schema/terms/weigth",
                              :object => "#{value}",
                              :resource => Resource.last,
                              :subject => TaxonConcept.find(1),
                              :unit => "http://purl.obolibrary.org/obo/UO_0000009",
                              :life_stage => l,
                              :sex => s,
                              :statistical_method => sm,
                              :normalized_value => "#{value*10}",
                              :normalized_unit => "http://purl.obolibrary.org/obo/UO_0000021").add_to_triplestore
          value += 2
        end
      end
    end
  end
end
