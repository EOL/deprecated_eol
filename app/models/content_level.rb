# All HierarchyEntry objects--and by extension all TaxonConcept objects--have a ContentLevel, which gives us a basic metric of how
# much data we have for that object: 1 meaning minimal content (0 meaning nothing but a name), and 4 meaning we have a rich page.
#
# There are other features around the site that restrict views/searches to only the richer objects.
class ContentLevel

  # class to represent content levels available in the system

  attr_reader :id,:name,:short_name

  def initialize(id,name,short_name)
    @id=id
    @name=name
    @short_name=short_name
  end

  # List of content level IDs on specific page banner to user
  def self.description_by_id(id)
    return case id.to_s
      when '1' then I18n.t(:minimal_page)
      else ''
    end
  end

  def self.find()

    # list of content codes for drop-down menu
    list=Array.new

    list << self.new('1', I18n.t(:all_pages) , I18n.t(:all_pages) )
  #  list << self.new('2', I18n.t(:view_only_pages_with_at_least_a_picture_or_piece_of_text) , I18n.t(:pages_with_pictures_or_text) )
    list << self.new('4', I18n.t(:just_pages_with_pictures_and_text) , I18n.t(:pages_with_pictures_and_text) )

    return list

  end

end
