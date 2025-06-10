raw_public_key = ENV['BFF_PUBLIC_KEY']

if raw_public_key.present?
  begin
    BFF_PUBLIC_KEY = OpenSSL::PKey.read(raw_public_key)
    Rails.logger.info("Successfully loaded BFF public key.")
  rescue OpenSSL::PKey::PKeyError => e
    Rails.logger.error("Failed to load BFF public key: #{e.message}")
    BFF_PUBLIC_KEY = nil
  end
else
  Rails.logger.warn("BFF_PUBLIC_KEY environment variable is not set.") unless Rails.env.development?
  BFF_PUBLIC_KEY = nil
end
