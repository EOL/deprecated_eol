# This is a class used by Tramea.
class Credit < ActiveRecord::Base
  belongs_to :credited_for, polymorphic: true # Image, Article, etc.

  def self.from_data_object(dato, credited_for)
    # TODO: if the data object was associated to a taxon by a curator, they
    # are credited as a supplier. (At the time of this writing, I don't have
    # associations here.)
    supplier = dato.try(:users_data_object).try(:user)
    if supplier
      credited_for.credits << create(
        credited_for: credited_for,
        name: supplier.full_name,
        role: "Supplier",
        url: "http://eol.org/users/#{supplier.id}" # TODO: don't hardcode url.
      )
      if dato.source_url
        credited_for.credits << create(
          credited_for: credited_for,
          name: "View Source",
          role: "Source",
          url: dato.source_url
        )
      end
    end
    dato.agents_data_objects.each do |ado|
      credited_for.credits << create(
        credited_for: credited_for,
        name: ado.agent.full_name,
        role: ado.agent_role.try(:label) || "unknown",
        url: ado.agent.homepage
      )
    end
    if dato.bibliographic_citation_for_display
      credited_for.credits << create(
        credited_for: credited_for,
        name: dato.bibliographic_citation_for_display,
        role: "Citation"
      )
    end
    if dato.location
      credited_for.credits << create(
        credited_for: credited_for,
        name: dato.location,
        role: "Location Created"
      )
    end
    if dato.spatial_location
      credited_for.credits << create(
        credited_for: credited_for,
        name: dato.spatial_location,
        role: "Location"
      )
    end
    # NOTE: setting source to translator, if this is translated:
    source = dato.translated_from || dato
    if source.try(:content_partner) && ! source.added_by_user?
      credited_for.credits << create(
        credited_for: credited_for,
        name: source.content_partner.name,
        role: "Source",
        url: source.source_url
      )
      if source.content_partner.homepage
        credited_for.credits << create(
          credited_for: credited_for,
          name: source.content_partner.name,
          role: "Partner Website",
          url: source.content_partner.homepage
        )
      end
    end
    credited_for.credits
  end
end
