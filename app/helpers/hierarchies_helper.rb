module HierarchiesHelper

  def en_browsable_status(hierarchy)
    if hierarchy.blank?
      'unknown'
    elsif hierarchy.browsable?
      'browsable'
    elsif hierarchy.request_publish
      'request_publish'
    else
      'not_browsable'
    end
  end
end