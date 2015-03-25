# This is a class used by Tramea.
class Article < ActiveRecord::Base
  has_many :contents
  has_many :credits

  def self.from_data_object(dato)
    raise "Must be an article" unless dato.article?
    # NOTE: I didn't do Image like this; wanted to try each and decide which I
    # prefer.
    return find_by_data_object_id(dato.id) if
      exists?(data_object_id: dato.id)
    article = create({
      data_object_id: dato.id,
      guid: dato.guid,
      title: dato.object_title,
      language: dato.language.iso_639_1,
      # NOTE: I removed an autolink here (it wasn't working in the model,
      # belongs in the view) NOTE: Yes, I too am tearing my hair out:
      body_html: Sanitize.clean(
          dato.description.balance_tags,
          Sanitize::Config::RELAXED
        ).fix_old_user_added_text_linebreaks(wrap_in_paragraph: true)
    }.merge(license_from_data_object(dato)).
      merge(UsersDataObjectsRating.params_from_data_object(dato)))
    dato.toc_items.compact.each do |toc_item|
      Section.create(toc_item: toc_item, article: article)
    end
    Ref.from_data_object(dato, article)
    Credit.from_data_object(dato, article)
    article
  end
end
