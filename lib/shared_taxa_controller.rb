module SharedTaxaController
  ########################################################################################################
  # Notice: those methods are taken from other controllers to be shared with the mobile app.             #
  # TO-DO by the maintainers: remove those methods from original controllers and include the module      #
  ########################################################################################################

  # from taxa_controller
  # If you want this to redirect to search, call (do_the_search && return if this_request_is_really_a_search) before this.
  def find_taxon_concept
    tc_id = params[:id].to_i
    tc_id = params[:taxon_id].to_i if tc_id == 0
    tc_id = params[:taxon_concept_id].to_i if tc_id == 0
    TaxonConcept.find(tc_id)
  end


  private

  # from taxa_controller
  def instantiate_taxon_concept
    @taxon_concept = find_taxon_concept
  end

  # from taxa_controller
  def promote_exemplar(data_objects)
    return data_objects if @taxon_concept.blank? || data_objects.blank? || @taxon_concept.taxon_concept_exemplar_image.blank?
    data_objects.each_with_index do |m, index|
      if m.id == @taxon_concept.taxon_concept_exemplar_image.data_object_id
        data_objects.delete_at(index)
        data_objects.unshift(m)
        break
      end
    end
    data_objects
  end
end
