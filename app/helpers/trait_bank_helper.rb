module TraitBankHelper
  def format_value(trait)
    value = trait.value_name.html_safe
    return "[data missing]" if value.nil?
    if trait.association?
      value = link_to(value, trait.target_taxon_uri)
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
      value = value.to_s.add_missing_hyperlinks.html_safe
    end
    if trait.units?
      value += " #{add_superscripts(trait.units_name)}".html_safe
    end
    if trait.sex
      value += " <span class='stat'>#{trait.sex_name}</span>".html_safe
    end
    if trait.life_stage
      value += " <span class='stat'>#{trait.life_stage_name}</span>".html_safe
    end
    value
  end

  def add_superscripts(str)
    str.to_s.gsub(/\^2\b/, "&sup2;").
      gsub(/\^3\b/, "&sup3;").
      gsub(/\^(\S+)/, "<sup>\\1</sup>")
  end
end
