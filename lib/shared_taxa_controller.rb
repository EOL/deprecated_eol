module SharedTaxaController
  ########################################################################################################
  # Notice: those methods are taken from other controllers to be shared with the mobile app.             #
  # TO-DO by the maintainers: remove those methods from original controllers and include the module      #
  ########################################################################################################

  # TODO: this file is likely out of date since mobile development has not kept up with V2 post launch development.

  private

  # from taxa_controller
  def instantiate_taxon_concept
    @taxon_concept = TaxonConcept.find(params[:taxon_concept_id] || params[:taxon_id] || params[:id])
    raise EOL::Exceptions::SecurityViolation, "User with ID=#{current_user.id} does not have access to TaxonConcept with id=#{@taxon_concept.id}" unless @taxon_concept.published?
  end

  # from taxa_controller
  def promote_exemplar_image(data_objects)
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
