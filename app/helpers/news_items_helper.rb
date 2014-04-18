module NewsItemHelper

  def content_teaser(news_item)
    if news_item.body.blank?
      ""
    else
      full_teaser = Sanitize.clean(news_item.body[0..300], elements: %w[b i], remove_contents: %w[table script]).strip
      return nil if full_teaser.blank?
      truncated_teaser = full_teaser.split[0..20].join(' ').balance_tags
      truncated_teaser << '...' if full_teaser.length > truncated_teaser.length
      truncated_teaser
    end
  end

end
