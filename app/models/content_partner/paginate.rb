class ContentPartner::Paginate

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

  CONDITIONS = 'content_partners.public = 1 AND '\
               'content_partners.full_name LIKE :name'

  INCLUDE = [{ resources: [:resource_status] }, :content_partner_status,
             :content_partner_contacts]

  def initialize(page, name, sort_by)
    @page = page
    @name = name
    @sort_by = sort_by
  end

  def run
     ContentPartner.paginate(
       page: @page,
       per_page: 10,
       select: SELECT_ITEMS,
       include: INCLUDE,
       conditions: [conditions, { name: "%#{@name}%" }],
       order: get_order
     )
  end

  private

  def get_order
    case @sort_by
    when 'newest'
      'content_partners.created_at DESC'
    when 'oldest'
      'content_partners.created_at'
    else
      'content_partners.full_name'
    end
  end

end
