class EntriesExplanation
  def initialize(taxon_concept, entries)
    @page = {
      name: taxon_concept.title,
      url: "http://eol.org/pages/#{taxon_concept.id}/overview",
      id: taxon_concept.id,
      ancestors: [], hierarchies: []
    }
    add_ancestors(taxon_concept)
    add_entries(entries)
  end

  def add_ancestors(concept)
    grouped_ancestors = concept.flattened_ancestors.group_by(&:ancestor_id)
    grouped_ancestors.each do |aid, ancestors|
      next if aid == 0
      @page[:ancestors] << {
        title: ancestors.first.ancestor.title,
        url: "http://eol.org/pages/#{ancestors.first.ancestor_id}/overview",
        via: ancestors.map do |a|
          { name: a.hierarchy.label,
            url: "http://eol.org/pages/#{a.hierarchy_entry.taxon_concept_id}/"\
              "hierarchy_entries/#{a.hierarchy_entry_id}/overview"
          }
        end
      }
    end
  end

  def add_entries(entries)
    grouped = entries.group_by(&:hierarchy)
    grouped.keys.sort_by { |k| k.label }.each do |hierarchy|
      h_data = { name: hierarchy.label, id: hierarchy.id, entries: [] }
      if hierarchy.resource
        h_data[:resource] = { name: hierarchy.resource.title, url: "http://eol.org/resources/#{hierarchy.resource.id}" }
      end
      grouped[hierarchy].each do |he|
        h_data[:entries] << {
          name: he.name.string,
          canonical: he.name.canonical_form.string,
          id: he.id,
          ancestors: he.flat_ancestors.map do |a|
            { canonical: a.canonical_form.string, url: "http://eol.org/pages/#{a.taxon_concept_id}", id: a.id }
          end
        }
      end
      @page[:hierarchies] << h_data
    end
  end


  def to_md
    str = "\n\n## [#{@page[:name]}](#{@page[:url]}) (#{@page[:id]})"
    str += "\n##### ancestors:"
    @page[:ancestors].each do |ancestor|
      str += "\n[#{ancestor[:title]}](#{ancestor[:url]}) via: "
      ancestor[:via].each do |entry|
        str += "[#{entry[:name]}](#{entry[:url]})"
      end.join(", ")
    end
    str += "\n"
    @page[:hierarchies].each do |hierarchy|
      if resource = hierarchy[:resource]
        str += "\n##### [#{resource[:name]}](#{resource[:url]}) "\
          "Hierarchy label: \"#{hierarchy[:name]}\" ```#{hierarchy[:id]}```"
      else
        str += "\n##### Hierarchy label: #{hierarchy[:name]} (no resource "\
          "available) ```#{hierarchy[:id]}```"
      end
      hierarchy[:entries].each do |he|
        str += "\n* *#{he[:name]}* (*#{he[:canonical]}*) ```#{he[:id]}``` -- **flat_ancestors**: "
        he[:ancestors].each do |a|
          str += "[#{a[:canonical]}](#{a[:url]}}) ```#{a[:id]}``` "
        end
        str += "(none)" if he[:ancestors].empty?
      end
      str += "\n"
    end
    str
  end

  def to_html
    str = "<h2><a href='#{@page[:url]}'>#{@page[:name]}</a> (#{@page[:id]})</h2>"
    str += "<h3>Ancestors:</h3>\n<p>Content associated with this page will also "\
      "appear on all of the following \"higher-level\" pages:</p><p><ul>\n"
    @page[:ancestors].each do |ancestor|
      str += "  <li><a href='#{ancestor[:url]}'>#{ancestor[:title]}</a> via: "
      ancestor[:via].each do |entry|
        str += "<a href='#{entry[:url]}'>#{entry[:name]}</a>"
      end.join(", ")
      str += "</li>\n"
    end
    str += "</ul></p><p><br/></p><h3>Hierarchies</h3>\n<p>This taxon concept is "\
      "comprised of data from the following hierarchies, which have "\
      "one or more entries directly associated with this concept:</p>\n<p>\n"
    str += "  <ul>\n"
    @page[:hierarchies].each do |hierarchy|
      if resource = hierarchy[:resource]
        str += "    <li><b><a href='#{resource[:url]}'>#{resource[:name]}</a></b> "\
          "Hierarchy label: \"#{hierarchy[:name]}\" (#{hierarchy[:id]})"
      else
        str += "    <li><b>Hierarchy label: #{hierarchy[:name]}</b> [no resource "\
          "available] (#{hierarchy[:id]})\n"
      end
      str += "    <ul>\n"
      hierarchy[:entries].each do |he|
        str += "      <li><i>#{he[:name]}</i> (<i>#{he[:canonical]}</i>) (#{he[:id]}) -- <b>flat_ancestors:</b> "
        he[:ancestors].each do |a|
          str += "<a href='#{a[:url]}'>#{a[:canonical]}</a> (#{a[:id]}) "
        end
        str += "(none)" if he[:ancestors].empty?
        str += "</li>\n"
      end
      str += "    </ul>\n    </li>\n"
    end
    str += "  </ul>\n</p>\n"
    str
  end

end
