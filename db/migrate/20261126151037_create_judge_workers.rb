# ジャッジサーバごとの状態。worker が起動時と heartbeat で書く
class CreateJudgeWorkers < ActiveRecord::Migration[8.1]
  def change
    create_table :judge_workers, id: { type: :string, limit: 64 } do |t| # id の例: judge-1-01HZX…
      t.string   :hostname,  null: false
      t.string   :image_tag, null: false
      t.string   :cpu_model
      t.integer  :slots,     null: false
      t.integer  :bench_ms
      t.boolean  :accepting, null: false, default: true # false にするとジョブを取らない
      t.datetime :started_at,   precision: 6, null: false
      t.datetime :heartbeat_at, precision: 6, null: false
    end
  end
end
