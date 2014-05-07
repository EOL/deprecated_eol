class Admins::TranslatedContentPagesController < AdminsController

  skip_before_filter :restrict_to_admins
  before_filter :restrict_to_admins_and_cms_editors

  # GET /admin/content_pages/:content_page_id/translations/new
  def new
    @content_page = ContentPage.find(params[:content_page_id])
    set_translated_content_page_new_options
    @translated_content_page = @content_page.translations.build(language_id: @languages.first.id, active_translation: true)
  end

  # POST /admin/content_pages/:content_page_id/translations
  def create
    @content_page = ContentPage.find(params[:content_page_id])
    @translated_content_page = @content_page.translations.build(params[:translated_content_page])
    @content_page.last_update_user_id = current_user.id unless @content_page.blank?
    if @content_page.save
      flash[:notice] = I18n.t(:admin_translated_content_page_create_successful_notice,
                              page_name: @content_page.page_name,
                              anchor: @content_page.page_name.gsub(' ', '_').downcase)
      redirect_to admin_content_pages_path(anchor: @content_page.page_name.gsub(' ', '_').downcase)
    else
      flash.now[:error] = I18n.t(:admin_translated_content_page_create_unsuccessful_error)
      set_translated_content_page_new_options
      render :new
    end
  end

  # GET /admin/content_pages/:content_page_id/translations/:id/edit
  def edit
    @content_page = ContentPage.find(params[:content_page_id], include: [:translations])
    @translated_content_page = @content_page.translations.find(params[:id])
    set_translated_content_page_edit_options
  end

  # PUT /admin/content_pages/:content_page_id/translations/:id
  def update
    if @translated_content_page = TranslatedContentPage.find(params[:id])
      older_version = @translated_content_page.dup
      if @translated_content_page.update_attributes(params[:translated_content_page])
        @content_page = ContentPage.find(params[:content_page_id], include: :translations)
        @content_page.last_update_user_id = current_user.id
        @content_page.save
        archive_fields = older_version.attributes.delete_if{ |k,v| [ 'id', 'active_translation' ].include?(k) }.
          merge(translated_content_page_id: older_version.id, original_creation_date: older_version.created_at)
        TranslatedContentPageArchive.create(archive_fields)
        flash[:notice] = I18n.t(:admin_translated_content_page_update_successful_notice,
                                page_name: @content_page.page_name,
                                language: @translated_content_page.language.label,
                                anchor: @content_page.page_name.gsub(' ', '_').downcase)
        redirect_to admin_content_pages_path(anchor: @content_page.page_name.gsub(' ', '_').downcase)
      else
        @content_page = ContentPage.find(params[:content_page_id], include: :translations)
        flash.now[:error] = I18n.t(:admin_translated_content_page_update_unsuccessful_error)
        set_translated_content_page_edit_options
        render :edit
      end
    end
  end

  # DELETE /admin/content_pages/:content_page_id/translations/:id
  def destroy
    return redirect_to action: 'index', status: :moved_permanently unless request.delete?
    content_page = ContentPage.find(params[:content_page_id])
    page_name = content_page.page_name
    translated_content_page = TranslatedContentPage.find(params[:id], include: :language)
    language = translated_content_page.language
    translated_content_page.destroy
    flash[:notice] = I18n.t(:admin_translated_content_page_delete_successful_notice,
                            page_name: page_name, language: language.label)
    redirect_to admin_content_pages_path, status: :moved_permanently
  end

private

  def set_translated_content_pages_options
    @page_title = I18n.t(:admin_content_pages_page_title)
  end

  def set_translated_content_page_new_options
    set_translated_content_pages_options
    @languages = @content_page.not_available_in_languages(nil)
    @page_subheader = I18n.t(:admin_translated_content_page_new_subheader,
                             page_name: @content_page.page_name)
    @navigation_tree = ContentPage.get_navigation_tree(@content_page.id)
  end

  def set_translated_content_page_edit_options
    set_translated_content_pages_options
    @page_subheader = I18n.t(:admin_translated_content_page_edit_subheader,
                             page_name: @content_page.page_name,
                             language: @translated_content_page.language.label.downcase)
    @navigation_tree = ContentPage.get_navigation_tree(@content_page.id)
  end

end
