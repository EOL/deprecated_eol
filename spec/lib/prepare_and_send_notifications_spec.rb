;require "spec_helper"

describe PrepareAndSendNotifications do

  it 'uses notification queue' do
    expect(PrepareAndSendNotifications.class_eval { @queue }).to eq("notifications")
  end

  describe '.perform' do

    context 'after notifications already sent' do

      before do
        allow(PendingNotification).to receive(:send_notifications)
        allow(NotificationEmailerSettings).to receive(:last_daily_emails_sent) { Time.now }
        allow(NotificationEmailerSettings).to receive(:last_weekly_emails_sent) { Time.now }
      end

      it 'send immediate notifications' do
        PrepareAndSendNotifications.perform
        expect(PendingNotification).to have_received(:send_notifications).with(:immediately)
      end

      it 'does NOT send daily notifications' do
        PrepareAndSendNotifications.perform
        expect(PendingNotification).to_not have_received(:send_notifications).with(:daily)
      end

      it 'does NOT send weekly notifications' do
        PrepareAndSendNotifications.perform
        expect(PendingNotification).to_not have_received(:send_notifications).with(:weekly)
      end

    end

    context 'after daily already sent' do

      before do
        allow(PendingNotification).to receive(:send_notifications)
        allow(NotificationEmailerSettings).to receive(:last_daily_emails_sent) { Time.now }
        allow(NotificationEmailerSettings).to receive(:last_weekly_emails_sent) { 3.weeks.ago }
      end

      it 'send immediate notifications' do
        PrepareAndSendNotifications.perform
        expect(PendingNotification).to have_received(:send_notifications).with(:immediately)
      end

      it 'does NOT send daily notifications' do
        PrepareAndSendNotifications.perform
        expect(PendingNotification).to_not have_received(:send_notifications).with(:daily)
      end

      it 'sends weekly notifications' do
        PrepareAndSendNotifications.perform
        expect(PendingNotification).to have_received(:send_notifications).with(:weekly)
      end

    end

    context 'after weekly already sent' do

      before do
        allow(PendingNotification).to receive(:send_notifications)
        allow(NotificationEmailerSettings).to receive(:last_daily_emails_sent) { 2.days.ago }
        allow(NotificationEmailerSettings).to receive(:last_weekly_emails_sent) { Time.now }
      end

      it 'send immediate notifications' do
        PrepareAndSendNotifications.perform
        expect(PendingNotification).to have_received(:send_notifications).with(:immediately)
      end

      it 'sends daily notifications' do
        PrepareAndSendNotifications.perform
        expect(PendingNotification).to have_received(:send_notifications).with(:daily)
      end

      it 'does NOT send weekly notifications' do
        PrepareAndSendNotifications.perform
        expect(PendingNotification).to_not have_received(:send_notifications).with(:weekly)
      end

    end

  end

end
