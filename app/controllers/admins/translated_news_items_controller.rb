class Admins::TranslatedNewsItemsController < AdminsController

  # GET /admin/news_items/:news_item_id/translations/new
  def new
    @news_item = NewsItem.find(params[:news_item_id])
    set_translated_news_item_new_options
    @translated_news_item = @news_item.translations.build(language_id: @languages.first.id, active_translation: true)
  end

  # POST /admin/news_items/:news_item_id/translations
  def create
    @news_item = NewsItem.find(params[:news_item_id])
    @translated_news_item = @news_item.translations.build(params[:translated_news_item])
    @news_item.last_update_user_id = current_user.id unless @news_item.blank?
    if @news_item.save
      flash[:notice] = I18n.t(:admin_translated_news_item_create_successful_notice,
                              page_name: @news_item.page_name,
                              anchor: @news_item.page_name.gsub(' ', '_').downcase)
      redirect_to news_items_path(anchor: @news_item.page_name.gsub(' ', '_').downcase)
    else
      flash.now[:error] = I18n.t(:admin_translated_news_item_create_unsuccessful_error)
      set_translated_news_item_new_options
      render :new
    end
  end

  # GET /admin/news_items/:news_item_id/translations/:id/edit
  def edit
    @news_item = NewsItem.find(params[:news_item_id], include: [:translations])
    @translated_news_item = @news_item.translations.find(params[:id])
    set_translated_news_item_edit_options
  end

  # PUT /admin/news_items/:news_item_id/translations/:id
  def update
    @translated_news_item = TranslatedNewsItem.find(params[:id])
    if @translated_news_item.update_attributes(params[:translated_news_item])
      @news_item = NewsItem.find(params[:news_item_id], include: :translations)
      @news_item.last_update_user_id = current_user.id
      @news_item.save
      flash[:notice] = I18n.t(:admin_translated_news_item_update_successful_notice,
                              page_name: @news_item.page_name,
                              language: @translated_news_item.language.label,
                              anchor: @news_item.page_name.gsub(' ', '_').downcase)
      redirect_to news_items_path(anchor: @news_item.page_name.gsub(' ', '_').downcase)
    else
      @news_item = NewsItem.find(params[:news_item_id], include: :translations)
      flash.now[:error] = I18n.t(:admin_translated_news_item_update_unsuccessful_error)
      set_translated_news_item_edit_options
      render :edit
    end
  end

  # DELETE /admin/news_items/:news_item_id/translations/:id
  def destroy
    return redirect_to action: 'index', status: :moved_permanently unless request.delete?
    news_item = NewsItem.find(params[:news_item_id])
    page_name = news_item.page_name
    translated_news_item = TranslatedNewsItem.find(params[:id], include: :language)
    language = translated_news_item.language
    translated_news_item.destroy
    flash[:notice] = I18n.t(:admin_translated_news_item_delete_successful_notice,
                            page_name: page_name, language: language.label)
    redirect_to news_items_path, status: :moved_permanently
  end

private

  def set_translated_news_item_options
    @page_title = I18n.t(:admin_news_items_page_title)
  end

  def set_translated_news_item_new_options
    set_translated_news_item_options
    @languages = @news_item.not_available_in_languages(nil)
    @page_subheader = I18n.t(:admin_translated_news_item_new_subheader,
                             page_name: @news_item.page_name)
  end

  def set_translated_news_item_edit_options
    set_translated_news_item_options
    @page_subheader = I18n.t(:admin_translated_news_item_edit_subheader,
                             page_name: @news_item.page_name,
                             language: @translated_news_item.language.label.downcase)
  end

end
