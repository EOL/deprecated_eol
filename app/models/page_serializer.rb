class PageSerializer
  # TODO:
  # * "provider" for media needs to include the partner's full name.
  # * "media_type" can be skipped; it's implied.
  # * skip "format" for images. Implied.
  # * Check that licenses come across with "name" "source_url", a working "icon_url" and "can_be_chosen_by_partners". ...I think they do, but the icon_url apears to be borked.
  # * references. ...not for this version, buy mark it as TODO.
  # * attributions. Crappy. ...i think we can skip it for the very first version, but soon TODO
  # * sections. Argh. Totally need this for the article, anyway. ...I suppose not RIGHT away, though...
  # * ratings are also TODO, though lower priority.
  # * Think about page content positions. :S
  # * Look at the "media type" that the map comes over as. Looks wrong.
  def self.store_page_id(pid)
    # Test with 328598 (Raccoon)
    page = { id: pid, moved_to_node_id: nil }
    # First, get it with supercedure:
    concept = TaxonConcept.find(pid)
    # Then, get it with includes:
    concept = TaxonConcept.where(id: concept.id).
      includes(
        :collections,
        preferred_common_names: [ :name ],
        preferred_entry: [ hierarchy_entry: [ :name, :rank, hierarchy: [ :resource ],
          flattened_ancestors: [ ancestor: :name ] ] ],
      ).first
    node = concept.entry
    resource = node.hierarchy.resource
    page[:native_node] = {
      id: node.id,
      resource: { id: resource.id, name: resource.title }, # more later...
      rank: { id: node.rank.id, name: node.rank.label },
      parent_id: node.parent_id,
      lft: node.lft,
      rgt: node.rgt,
      scientific_name: node.italicized_name,
      canonical_form: node.title_canonical_italicized,
      resource_pk: node.identifier,
      source_url: node.source_url,
      is_hidden: false
      ancestors: [
        node.ancestors.map do |a|
          { id: a.id,
            resource_id: resource.id,
            rank: { id: a.rank.id, name: a.rank.label },
            parent_id: a.parent_id,
            lft: node.lft,
            rgt: node.rgt,
            scientific_name: node.italicized_name,
            canonical_form: node.title_canonical_italicized,
            resource_pk: node.identifier,
            source_url: node.source_url,
            is_hidden: false
          }
        end
      ]
    }
    page[:vernaculars] = concept.preferred_common_names.map do |cn|
      l_code = cn.language.iso_639_3
      l_code = "eng" if l_code.blank?
      l_grp = cn.language.iso_639_1
      l_grp = "en" if l_code.blank?
      { string: cn.name.string,
        language: { id: cn.language.id, code: l_code, group: l_grp },
        preferred: preferred?,
        preferred_by_resource: preferred?,
        is_hidden: false
      }
    end
    page[:media] = "YOU WERE HERE"
  end
end
