# frozen_string_literal: true

# config.active_storage.draw_routes = false にしているため、test の Disk サービスが
# 署名付き URL の生成に使う update_rails_disk_service_url が存在しない。
# テストではブラウザからの PUT を行わないので、固定の URL を返すように差し替える。
require 'active_storage/service/disk_service'

ActiveStorage::Service::DiskService.prepend(Module.new do
  def url_for_direct_upload(key, **)
    "https://storage.example.test/direct_uploads/#{key}"
  end
end)
