class Utils::BffValidator
  def initialize(signature, timestamp, method, path, body)
    @signature = signature
    @timestamp_string = timestamp
    @method = method
    @path = path
    @body = body
  end


  def validate
    unless @signature.present? && @timestamp_string.present?
      return false
    end

    unless check_timestamp.present?
      return false
    end

    begin
      decoded_signature = Base64.decode64(@signature)
      is_valid = BFF_PUBLIC_KEY.verify(
        nil,
        decoded_signature,
        signed_data
      )
      return is_valid
    rescue  => e
      Rails.logger.error("Signature verification failed: #{e.message}")
      return false
    end
  end

  private

  def check_timestamp
    begin
      timestamp = Time.iso8601(@timestamp_string)
      p Time.now.utc, timestamp, (Time.now.utc - timestamp).abs
      if (Time.now.utc - timestamp).abs > 1.minute
        return nil
      end
    rescue ArgumentError
      return nil
    end
    @timestamp = timestamp
  end

  def signed_data
    [@timestamp_string, @method, @path, @body].join('.')
  end

end
