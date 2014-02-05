require "spec_helper"

describe ContactsController do

  before(:all) do
    unless @user = User.find_by_username('contacts_controller_spec')
      truncate_all_tables
      Language.create_english
      CuratorLevel.create_enumerated
      @user = User.gen(:username => 'contacts_controller_spec')
      unless @contact_subject = ContactSubject.first
        @contact_subject = ContactSubject.gen_if_not_exists(:title => "Fake contact subject")
      end
    end
  end

  describe 'GET new' do
    it 'should assign default parameters to contact and render new' do
      controller.instance_eval{ contact_subjects }
      get :new
      assigns[:contact].should be_a(Contact)
      assigns[:contact].ip_address.should == request.remote_ip
      assigns[:contact_subjects].first.should be_a(ContactSubject)
      response.should render_template('contacts/new')
    end
    it 'should preload current user details if logged in' do
      get :new
      assigns[:contact].user_id.should be_nil
      assigns[:contact].name.should be_nil
      assigns[:contact].email.should be_nil
      get :new, nil, { :user_id => @user.id }
      assigns[:contact].user_id.should == @user.id
      assigns[:contact].name.should == @user.full_name
      assigns[:contact].email.should == @user.email
    end
    it 'should record referred page if provided' do
      get :new
      assigns[:contact].referred_page.should be_blank
      referred_page = '/some/page/url'
      get :new, { :referred_page => referred_page }
      assigns[:contact].referred_page.should == referred_page
    end
  end

  describe 'POST create' do
    before :all do
      @new_contact_params = { :contact => { :name => 'A name', :email => 'test@test.com',
                                    :comments => 'Message', :contact_subject_id => 1,
                                    :user_id => 1 } }
    end

    it 'should not create or deliver email if record is invalid' do
      controller.instance_eval { flash.stub(:sweep) }
      Notifier.should_not_receive(:contact_us_auto_response)
      Notifier.should_not_receive(:contact_us_message)
      post :create
      flash.now[:error].should_not be_blank
      response.should render_template('contacts/new')
    end

    it 'should create contact' do
      new_contact_params = @new_contact_params.dup
      new_contact_params[:contact][:name] = 'Mr. Pink'
      post :create, new_contact_params, { :user_id => 1 }
      Contact.last.name.should == new_contact_params[:contact][:name]
      expect(response).to redirect_to(contact_us_path)
    end

    it 'should append current user URL to message if logged in' do
      post :create, @new_contact_params, { :user_id => 1 }
      assigns[:contact][:comments].should =~ /users\/1/
    end

    it 'should send auto response email' do
      mailer = double
      mailer.should_receive(:deliver)
      Notifier.should_receive(:contact_us_auto_response).and_return(mailer)
      post :create, @new_contact_params, { :user_id => 1 }
    end

    it 'should send feedback email' do
      mailer = double
      mailer.should_receive(:deliver)
      Notifier.should_receive(:contact_us_message).and_return(mailer)
      post :create, @new_contact_params, { :user_id => 1 }
    end

  end

  describe '#contact_subjects' do

    it 'should return active contact subjects' do
      controller.instance_eval{ contact_subjects }
      controller.instance_eval{ @contact_subjects }.should == ContactSubject.find_all_by_active(true)
    end

    it 'should not return inactive contact subjects' do
      contact_subject = ContactSubject.find_by_active(true)
      contact_subject.update_column(:active, false)
      controller.instance_eval{ contact_subjects }
      controller.instance_eval{ @contact_subjects }.select{ |cs| !cs.active? }.should be_blank
      contact_subject.update_column(:active, true)
    end

  end

end
