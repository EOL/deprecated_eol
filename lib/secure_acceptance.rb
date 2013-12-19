# NOTE - this file was provided by CyberSecurity and modified by the EOL team.
class SecureAcceptance

  require 'hmac-sha2'
  require 'base64'

  # EOL changed this, but NOTE that class variables are problematic (still, we're never going to subclass this):
  @secret_key = Rails.configuration.secure_acceptance[:secret_key]

  def self.generate_signature params
    sign(build_data_to_sign(params), @secret_key)
  end

  def self.valid? params
    signature = generate_signature params
    signature.strip.eql? params['signature'].strip
  end

  private # ... EOL NOTE - no class methods are truly private...  :\

  def self.sign data, secret_key
    mac = HMAC::SHA256.new secret_key
    mac.update data
    Base64.encode64(mac.digest).gsub "\n", ''
  end

  def self.build_data_to_sign params
    signed_field_names = params['signed_field_names'].split ','
    data_to_sign = Array.new
    signed_field_names.each { |signed_field_name|
      data_to_sign << signed_field_name + '=' + params[signed_field_name].to_s
    }
    comma_separate data_to_sign
  end

  def self.comma_separate data_to_sign
    csv = ''
    data_to_sign.length.times do |i|
      csv << data_to_sign[i]
      csv << ',' if i != data_to_sign.length-1
    end
    csv
  end

end
