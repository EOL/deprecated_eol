require File.dirname(__FILE__) + '/../spec_helper'

describe FeedsController do
  before(:all) do
    load_foundation_cache
  end

  it 'find Comment should redirect correctly with translations' do
    original = DataObject.gen(:created_at => 10.minutes.ago, :language => Language.from_iso('en'))
    update = DataObject.gen(:created_at => 5.minutes.ago, :guid => original.guid, :language => Language.from_iso('en'))
    translation = DataObject.gen(:created_at => Time.now, :guid => original.guid, :language => Language.from_iso('ar'))
    comment_on_original = Comment.gen(:parent => original)
    comment_on_translation = Comment.gen(:parent => translation)
    # comment on the original version will get redirected to latest version in language
    get :find, :id => comment_on_original.id, :type => 'Comment'
    expect(response).to redirect_to(data_object_path(update, :page => 1, :anchor => "Comment-#{comment_on_original.id}"))
    # comment on the translation will go to the translation
    get :find, :id => comment_on_translation.id, :type => 'Comment'
    expect(response).to redirect_to(data_object_path(translation, :page => 1, :anchor => "Comment-#{comment_on_translation.id}"))
  end

  it 'find UsersDataObject should redirect correctly with translations' do
    original = DataObject.gen(:created_at => 10.minutes.ago, :language => Language.from_iso('en'))
    original_udo = UsersDataObject.gen(:data_object => original)
    update = DataObject.gen(:created_at => 5.minutes.ago, :guid => original.guid, :language => Language.from_iso('en'))
    update_udo = UsersDataObject.gen(:data_object => update)
    translation = DataObject.gen(:created_at => Time.now, :guid => original.guid, :language => Language.from_iso('ar'))
    translation_udo = UsersDataObject.gen(:data_object => translation)
    # comment on the original version will get redirected to latest version in language
    get :find, :id => original_udo.id, :type => 'UsersDataObject'
    expect(response).to redirect_to(data_object_path(update, :page => 1, :anchor => "UsersDataObject-#{original_udo.id}"))
    # comment on the translation will go to the translation
    get :find, :id => translation_udo.id, :type => 'UsersDataObject'
    expect(response).to redirect_to(data_object_path(translation, :page => 1, :anchor => "UsersDataObject-#{translation_udo.id}"))
  end

end
