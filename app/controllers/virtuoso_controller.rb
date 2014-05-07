class VirtuosoController < ApplicationController

  skip_before_filter :original_request_params, :global_warning, :set_locale, :check_user_agreed_with_terms

  # go to a random data tab
  def data_tab
    taxon_concept = RandomHierarchyImage.random_set(1).first.taxon_concept
    return redirect_to taxon_data_path(taxon_concept.id)
  end

  # go to a random overview tab
  def overview_tab
    number_of_concepts = TaxonConcept.count
    taxon_concept = TaxonConcept.first(:offset => rand(number_of_concepts))
    return redirect_to taxon_overview_path(taxon_concept.id)
  end

  # perform some random range search
  def search
    from = rand(10000)
    to = from + rand(10000 - from)
    return redirect_to data_search_path(:q => "#{from} to #{to}")
  end

  # perform some random range search
  def load
    # taxon_concept = RandomHierarchyImage.random_set(1).first.taxon_concept
    taxon_concept = TaxonConcept.find_by_id(params[:id])
    taxon_page = TaxonPage.new(taxon_concept)
    taxon_data = taxon_page.data
    taxon_data.ranges_of_values
    taxon_data.raw_data
    render text: "Ok"
  end

  # add then delete some random data from Virtuoso
  def insert_and_delete
    number_of_concepts = TaxonConcept.count
    resource = Resource.last
    user = User.last
    taxon_concept = TaxonConcept.first(:offset => rand(number_of_concepts))
    target_taxon_concept = TaxonConcept.where("id != #{taxon_concept.id}").first(:offset => rand(number_of_concepts - 1))
    default_data_options = { :subject => taxon_concept, :resource => resource }

    iterations = 20
    measurements = []
    associations = []
    user_added_datas = []
    iterations.times do
      measurement = DataMeasurement.new(default_data_options.merge(:predicate => 'http://eol.org/measurement', :object => rand(10000).to_s, :unit => 'http://eol.org/g'))
      measurements << measurement
      measurement.update_triplestore
      association = DataAssociation.new(default_data_options.merge(:object => target_taxon_concept, :type => 'http://eol.org/association'))
      associations << association
      association.update_triplestore
      user_added_data = UserAddedData.create(:user => user, :subject => taxon_concept, :predicate => 'http://eol.org/user_added', :object => rand(10000).to_s)
      user_added_datas << user_added_data
    end
    measurements.each{ |m| m.remove_from_triplestore }
    associations.each{ |m| m.remove_from_triplestore }
    UserAddedData.destroy(user_added_datas)
    render :text => "Just completed #{iterations} additions/deletions of measurements, associations and user_added_data"
  end

end
