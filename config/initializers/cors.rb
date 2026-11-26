# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

# 許可するフロントエンドの origin
# localhost (pnpm dev のフロント) は開発環境だけで許可し、本番では許可しない
allowed_origins = ['https://mofecoder.com']
allowed_origins << 'http://localhost:8000' if Rails.env.development?

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)
    resource '*',
      headers: :any,
      expose: %w(access-token uid client expiry),
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
