# e.g.: s = SearchTraits.new(attribute: "http://purl.obolibrary.org/obo/OBA_0000056") ; 1
# trait = s.traits.first ; 1
# trait.to_hash
class TraitBank
  class ToHash
    def self.from(trait)
      language = Language.default
      hash = {}
      if trait.page
        # Taxon Concept ID:
        hash[I18n.t(:data_column_tc_id)] = trait.page.id,
        # WAIT - # Some classification context (stealing from search for now):
        # WAIT - I18n.t(:data_column_classification_summary) => trait.page.entry.preferred_classification_summary,
        # Scientific Name:
        hash[I18n.t(:data_column_sci_name)] = trait.page.title_canonical,
        # Common Name:
        hash[I18n.t(:data_column_common_name)] =
          trait.page.preferred_common_name_in_language(language)
      end
      # Nice measurement:
      hash[I18n.t(:data_column_measurement)] = trait.predicate_name
      hash[I18n.t(:data_column_value)] = trait.value_name
      # URI measurement / value
      uri = trait.predicate_uri.try(:uri)
      hash[I18n.t(:data_column_measurement_uri)] =
        EOL::Sparql.is_uri?(uri) ? uri : nil
      uri = trait.value_uri.try(:uri)
      hash[I18n.t(:data_column_value_uri)] =
        EOL::Sparql.is_uri?(uri) ? uri : nil
      # Units:
      hash[I18n.t(:data_column_units)] = trait.units_name
      # Units URI:
      uri = trait.units_uri.try(:uri)
      hash[I18n.t(:data_column_units_uri)] =
        EOL::Sparql.is_uri?(uri) ? uri : nil
      # Sources:
      hash[I18n.t(:data_column_source)] = trait.other_sources.join(" ")
      # Resource:
      if trait.resource
        hash[I18n.t(:data_column_resource)] =
          # Ewww. TODO - this really belongs in a view:
          Rails.application.routes.url_helpers.content_partner_resource_url(
            trait.resource.content_partner, trait.resource,
            host: EOL::Server.domain)
      end
      language ||= Language.english
      trait.meta.each do |pred, val|
        key = if pred.is_a?(KnownUri)
          pred.name
        else
          UnknownUri.new(pred).name
        end
        count = 1
        orig_key = key.dup
        while hash.has_key?(key) # Uh-oh. Make it original, please:
          key = "#{orig_key} #{count += 1}"
        end
        hash[key] = val.is_a?(KnownUri) ? val.name : val.to_s
      end
      hash
    end
  end
end
