# This is a class used by Tramea.
class Article < ActiveRecord::Base
  has_many :contents
  has_many :credits
  has_many :references

  def self.from_data_object(dato)
    raise "Must be an article" unless dato.article?
    return find_by_data_object_id(dato.id) if
      exists?(data_object_id: dato.id)
    article = create({
      # NOTE: I removed an autolink here (it wasn't working in the model,
      # belongs in the view) NOTE: Yes, I too am tearing my hair out:
      body: Sanitize.clean(
          dato.description.balance_tags,
          Sanitize::Config::RELAXED
        ).fix_old_user_added_text_linebreaks(wrap_in_paragraph: true)
    }.merge(Media.common_params_from_data_object(dato)))
    dato.toc_items.compact.each do |toc_item|
      Section.create(toc_item: toc_item, article: article)
    end
    Media.add_common_associations_from_data_object(dato, article)
    article
  end
end
