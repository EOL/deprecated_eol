class DonationsController < ApplicationController

  include ActionView::Helpers::NumberHelper

  before_filter :set_page_title

  layout 'basic'

  DONATION_MIN = 1.0

  # Form for a donation:
  def new
  end

  # Payment confirmation:
  def create
    donation = params[:donation]
    @other_amount = donation[:amount].gsub(",", "").to_f
    @preset_amount = donation[:preset_amount]

    flash[:error] = I18n.t(:donation_error_no_amount) if
      @preset_amount.nil?
    flash[:error] = I18n.t(:donation_error_minimum, min: number_to_currency(DONATION_MIN)) if
      (@preset_amount == "other" && @other_amount < DONATION_MIN)
    flash[:error] = I18n.t(:donation_error_only_numbers) if
      (@preset_amount == "other" && @other_amount == 0)

    return(redirect_to(action: :new)) if flash[:error]

    @page_title = I18n.t(:donation_confirmation)

    params['amount'] = @preset_amount.to_f > DONATION_MIN ? @preset_amount.to_f : @other_amount
    params['signed_date_time'] = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ") if params['signed_date_time'].blank?
    # NOTE this one MUST be done last:
    params['signature'] = SecureAcceptance.generate_signature(params) unless params['access_key'].blank?
  end

  # receipt:
  def show
    @signature_valid = SecureAcceptance.valid?(params)
  end

private

  def set_page_title
    @page_title = I18n.t(:donation_title)
  end

end
