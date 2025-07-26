# frozen_string_literal: true

module FirebaseAuthenticatable
  class AuthenticateError < StandardError; end

  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user_from_token!
  end

  def authenticate_user_from_token
    uid = authenticate_token['sub']
    unless uid
      return
    end
    current_user(uid)
  end

  def authenticate_token
    token = extract_token
    unless token
      @current_user = nil
      return
    end

    res = JWT.decode(token, nil, true, @options) do |header|
      cert = fetch_certificates[header['kid']]
      cert.present? ? OpenSSL::X509::Certificate.new(cert).public_key : nil
    end

    raise AuthenticateError.new('Invalid auth_time') unless Time.zone.at(payload['auth_time']).past?
    raise AuthenticateError.new('Invalid sub') if payload['sub'].empty?

    payload
  end


  def current_user(uid = nil)
    @current_user ||= User.find_by_uid(uid)
  end

  def user_signed_in?
    !!current_user
  end

  private

  ALG = 'RS256'
  ISSUER_BASE = 'https://securetoken.google.com/'
  PROJECT_ID = ENV["FIREBASE_PROJECT_ID"] || 'mofe-development'


  @options = {
    algorithm: ALG,
    verify_iat: true,
    aud: PROJECT_ID,
    verify_aud: true,
    iss: ISSUER_BASE + PROJECT_ID,
    verify_iss: true,
  }

  def extract_token
    request.headers['Authorization'].split(' ')&.last
  end

  CERTS_CACHE_KEY = '_firebase-auth-certs'
  CERTS_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'

  def fetch_certificates
    cached = Rails.cache.read(CERTS_CACHE_KEY)
    return cached if cached

    res = Net::HTTP::get_response(URI(CERTS_URL))
    raise 'Failed to fetch certificates' unless res.is_a?(Net::HTTPSuccess)

    body = JSON.parse(res.body)
    expires_at = Time.zone.parse(res.header['expires'])
    Rails.cache.write(CERTS_CACHE_KEY, body, expires_in: expires_at - Time.current)
  end
end
