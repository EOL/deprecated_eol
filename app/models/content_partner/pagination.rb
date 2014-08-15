# encoding: utf-8

class ContentPartner
  # Prepares data for WillPaginate gem
  class Pagination
    SELECT_ITEMS = %w(
      content_partners.id             content_partners.full_name
      content_partners.display_name   content_partners.description
      content_partners.homepage       content_partners.logo_cache_url
      content_partners.logo_file_name content_partners.logo_content_type
      content_partners.logo_file_size content_partners.created_at
      resources.id                    resources.collection_id
      resources.resource_status_id    resource_statuses.*
      harvest_events.*
    )

    CONDITIONS = "content_partners.public = 1 AND "\
                 "content_partners.full_name LIKE :name"

    INCLUDE = [{ resources: [:resource_status] }, :content_partner_status,
               :content_partner_contacts]

    attr_reader :index_meta

    def initialize(index_meta)
      @index_meta = index_meta
    end

    def self.paginate(index_meta)
      new(index_meta).paginate
    end

    def paginate
      # TODO: Select is being ignored in the following. Appears to be when
      # conditions added. Find a solution.
      ContentPartner.paginate(
        page: index_meta.page,
        per_page: 10,
        select: SELECT_ITEMS,
        include: INCLUDE,
        conditions: [CONDITIONS, { name: "%#{index_meta.name}%" }],
        order: order
      )
    end

    private

    def order
      case index_meta.sort_by
      when "newest"
        "content_partners.created_at DESC"
      when "oldest"
        "content_partners.created_at"
      else
        "content_partners.full_name"
      end
    end
  end
end
