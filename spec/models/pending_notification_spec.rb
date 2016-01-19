require "spec_helper"

describe PendingNotification do

  before(:all) do
    NotificationFrequency.create_enumerated
    Activity.create_enumerated
    ChangeableObjectType.create_enumerated
  end

  # These have lambdas, so I want to test them.
  it 'scopes work' do
    NotificationFrequency.find_each do |type|
      # Skipping FactoryGirl, since it's not really needed:
      PendingNotification.create(notification_frequency: type)
    end
    PendingNotification.immediately.each do |note|
      expect(note.notification_frequency).to eq(NotificationFrequency.immediately)
    end
    PendingNotification.daily.each do |note|
      expect(note.notification_frequency).to eq(NotificationFrequency.daily)
    end
    PendingNotification.weekly.each do |note|
      expect(note.notification_frequency).to eq(NotificationFrequency.weekly)
    end
  end

  # NOTE - Gotta let scopes do their thang here, or there's too much
  # stubbing.
  describe '.send_notifications' do

    before(:all) do
      PendingNotification.delete_all
      @user = User.gen(email: 'not@blank.com')
      @user = User.select('id, email').find(@user.id)
      @unsent_target = CuratorActivityLog.gen(changeable_object_type:
                                              ChangeableObjectType.last)
      @sent_target = CuratorActivityLog.gen(changeable_object_type:
                                            ChangeableObjectType.last)
      @no_user_target = CuratorActivityLog.gen(changeable_object_type:
                                               ChangeableObjectType.last)
      @unsent = PendingNotification.create(
        notification_frequency: NotificationFrequency.daily,
        target: @unsent_target,
        user: @user
      )
      @sent = PendingNotification.create(
        notification_frequency: NotificationFrequency.daily,
        user: @user,
        target: @sent_target,
        sent_at: 1.minute.ago
      )
      @no_user = PendingNotification.create(
        notification_frequency: NotificationFrequency.daily,
        target: @no_user_target
      )
    end

    let(:mail_object) { double("mailer") }
    let(:error_mail_object) { double("error mailer") }

    before do
      allow(mail_object).to receive(:deliver)
      allow(error_mail_object).to receive(:deliver)
      allow(PendingNotification).to receive(:mark_as_sent) { ['a', ['b', 'c']] }
      allow(RecentActivityMailer).to receive(:recent_activity) { mail_object }
      allow(RecentActivityMailer).to receive(:notification_error) { error_mail_object }
    end

    it 'sends only notes that should go' do
      allow(RecentActivityMailer).to receive(:recent_activity) { mail_object }
      PendingNotification.send_notifications(:daily)
      expect(RecentActivityMailer).to have_received(:recent_activity).
        # NOTE that the other two targets aren't here:
        with(@user, [@unsent_target], :daily)
    end

    # Note that this requires the above array to be _flattened_
    it 'returns a count of sent notifications' do
      expect(PendingNotification.send_notifications(:daily)).to eq(3)
    end

    it 'marks messages as sent' do
      PendingNotification.send_notifications(:daily)
      expect(PendingNotification).to have_received(:mark_as_sent)
    end

    it 'sends error notification' do
      allow(RecentActivityMailer).to receive(:recent_activity).and_raise("Trouble")
      allow(RecentActivityMailer).to receive(:notification_error) { error_mail_object }
      PendingNotification.send_notifications(:daily)
      expect(RecentActivityMailer).to have_received(:notification_error)
      expect(error_mail_object).to have_received(:deliver)
    end

    it 'does NOT send error notification normally' do
      PendingNotification.send_notifications(:daily)
      expect(RecentActivityMailer).to_not have_received(:notification_error)
      expect(error_mail_object).to_not have_received(:deliver)
    end

  end

  describe '.mark_as_sent' do

    before do
      allow(PendingNotification.connection).to receive(:execute)
    end

    it 'skips it if nothing to do' do
      PendingNotification.mark_as_sent([])
      expect(PendingNotification.connection).to_not have_received(:execute)
    end

    # NOTE - I'm not going to put the whole query in the spec.
    it 'skips it if nothing to do' do
      PendingNotification.mark_as_sent([12,23])
      expect(PendingNotification.connection).to have_received(:execute)
    end

  end

end
