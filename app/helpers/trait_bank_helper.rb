module TraitBankHelper
  def format_value(trait)
    value = trait.value_name
    # TODO: associations. :\
    if trait.association?
      value = link_to(trait.target_taxon_name, trait.target_taxon_uri)
    elsif value.is_numeric? && ! trait.predicate_uri.treat_as_string?
      if value.is_float?
        if value.to_f < 0.1
          value = value.to_f.sigfig_to_s(3)
        else
          value = value.to_f.round(2)
        end
      end
      value = number_with_delimiter(value, delimiter: ',')
    else
      value = value.to_s.add_missing_hyperlinks
    end
    if trait.sex
      value += "<span class='stat'>#{trait.sex_name}</span>"
    end
    if trait.life_stage
      value += "<span class='stat'>#{trait.life_stage_name}</span>"
    end
    value
  end
end
