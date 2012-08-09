module ApplicationHelper

  # Link to a single stylesheet asset (which may be comprised of several individual files).
  # NOTE - Styles will only be cached for English. Sorry; impractical to maintain copies of all cached files for
  # every language.
  def stylesheet_include_i18n(stylesheet, options = {})
    if I18n.locale.to_s != 'ar' # Annoying that I have to check this, but c'est la vie. (See what I did there?)
      return include_stylesheets(*[stylesheet, options])
    else
      read_stylesheet_packages unless @stylesheet_packages
      raise "** UNKNOWN STYLESHEET LOADED: #{stylesheet}" unless @stylesheet_packages.has_key?(stylesheet.to_s)
      code = ''
      @stylesheet_packages[stylesheet.to_s].each do |file|
        language_stylesheet = "/languages/#{I18n.locale}/#{file}.css"
        if File.exists?(File.join(RAILS_ROOT, "public", language_stylesheet))
          code += stylesheet_link_tag(language_stylesheet, options)
        end
      end
      return code
    end
  end

end
