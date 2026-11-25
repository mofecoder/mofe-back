namespace :uploads do
  desc '完了しなかったアップロードと、どこにも付いていない blob をストレージから削除する'
  task cleanup: :environment do
    # rake はジョブの完了を待たずに終わるので、purge_later ではなく同期で削除する
    stale = Upload.stale_pending
    count = stale.count
    stale.find_each { |upload| upload.reject!(async: false) }
    puts "期限切れの pending を #{count} 件削除しました"

    # 削除のジョブ (:async) が再起動などで実行されなかったものを拾う
    orphans = ActiveStorage::Blob.unattached.where(created_at: ...1.day.ago)
    count = orphans.count
    orphans.find_each(&:purge)
    puts "どこにも付いていない blob を #{count} 件削除しました"
  end
end
