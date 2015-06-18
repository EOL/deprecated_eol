# This class represents a *collection* of the media (images, videos, and sounds) associated with a taxon concept,
# providing a minimal interface to the methods you might need to access such a thing and display it.
#
# NOTE that this class uses a plural name for a single instance; this is a fairly standard practice for these types of 
# Presenter objects, when appropriate.
class TaxonMedia < TaxonUserClassificationFilter

  attr_reader :type, :status, :per_page, :sort_by

  IMAGES_PER_PAGE  = $MAX_IMAGES_PER_PAGE # NOTE - misnomer. TODO - s/b IMAGES_PER_PAGE.
  MAXIMUM_IMAGES_PER_PAGE = 100 

  include Enumerable

  def initialize(taxon_concept, user, options = {})
    @page = options[:page] ||= 1
    @per_page = options[:per_page] ||= TaxonMedia::IMAGES_PER_PAGE
    @per_page = TaxonMedia::MAXIMUM_IMAGES_PER_PAGE if @per_page.to_i > TaxonMedia::MAXIMUM_IMAGES_PER_PAGE
    @sort_by = options[:sort_by] ||= 'status'
    @type = options[:type] ||= ['all']
    @type = ['all'] if @type.include?('all')
    @type = @type.values if @type.is_a?(Hash) # TODO - explain when/why this might happen.
    @status = options[:status] ||= ['all']
    @status = @status.values if @status.is_a?(Hash) # TODO - explain when/why this might happen.
    @exemplar_id = options[:exemplar_id]
    super(taxon_concept, user, options[:hierarchy_entry])
    get_media
  end

  def empty?
    media_count == 0
  end

  def start
    @start ||= (@page.to_i - 1) * @per_page.to_i + 1
  end

  def end
    @end ||= [ (start + @per_page.to_i - 1), media_count ].min
  end

  # You'll pass this to will_paginate.
  def paginated
    @media
  end

  def each
    @media.each { |img| yield(img) }
  end

  def rating_for_guid(guid)
    @ratings ||= user.ratings_for_guids(@media.map(&:guid))
    @ratings[guid] || 0
  end

  private

  # NOTE - Once you call this (with options), those options are preserved and you cannot call this with different
  # options. Be careful. (In practice, this never matters.)
  def get_media
    set_statuses
    @media ||= taxon_concept.data_objects_from_solr(
      ignore_translations: true,
      return_hierarchically_aggregated_objects: true,
      page: @page,
      per_page: @per_page,
      sort_by: @sort_by,
      data_type_ids: data_type_ids,
      vetted_types: @search_statuses,
      visibility_types: @visibility_statuses,
      exemplar_id: @exemplar_id,
      preload_select: { data_objects: [ :id, :guid, :language_id, :data_type_id, :created_at, :mime_type_id, :object_title,
                                              :object_cache_url, :object_url, :data_rating, :thumbnail_cache_url, :data_subtype_id,
                                              :published ] }
    )
    repair_bad_counts(@media.total_entries) # Doing this before preload in the off chance that that method alters counts.
    preload_media_details
    correct_bogus_exemplar_image     
    if (!@exemplar_id.blank? && (@page.nil? || @page == 1) && image)
      @media.unshift(image) # place exemplar image at the top of media page
    end
  end

  def repair_bad_counts(count)
    # NOTE: using #_hierarchy_entry because the value passed here should be nil when it's not specified.
    @taxon_concept.update_media_count(user: user, entry: _hierarchy_entry, with_count: count)
  end

  def set_statuses
    if @status.include?('all')
      if user.is_curator?
        @search_statuses = ['trusted', 'unreviewed', 'untrusted']
        @visibility_statuses = ['visible', 'invisible']
      else
        @search_statuses = ['trusted', 'unreviewed']
        @visibility_statuses = ['visible']
      end
    else
      @search_statuses = @status
    end
  end

  def data_type_ids
    return @data_type_ids if @data_type_ids
    @data_type_ids = []
    ['image', 'video', 'sound'].each do |t|
      next unless @type.include?(t)
      if t == 'video'
        @data_type_ids |= DataType.video_type_ids
      elsif data_type = DataType.cached_find_translated(:label, t, 'en')
        @data_type_ids |= [data_type.id]
      end
    end
    if @data_type_ids.empty?
      @data_type_ids = DataType.image_type_ids + DataType.video_type_ids + DataType.sound_type_ids
    end
    @data_type_ids
  end

  def preload_media_details
    # There should not be an older revision of exemplar image on the media tab. But recently there were few cases
    # found. Replace older revision of the exemplar image from media with the latest published revision.
    if image # If there's no exemplar image, don't bother...
      @media.map! { |m| (m.guid == image.guid && m.id != image.id) ? image : m }
    end
    TaxonUserClassificationFilter.preload_details(@media, user)
  end

end
