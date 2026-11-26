# go-judge の worker が判定の確保・延長・解放に使う列を追加する
class AddJudgeLeaseToSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :submissions, :judge_token,    :string,   limit: 26, null: true
    add_column :submissions, :judge_worker,   :string,   limit: 64, null: true # 判定後も残す（どのサーバで判定したか）
    add_column :submissions, :lease_until,    :datetime, precision: 6, null: true
    add_column :submissions, :judge_attempts, :integer,  limit: 1, null: false, default: 0
    add_index  :submissions, [:status, :updated_at]
    add_index  :submissions, :judge_token, unique: true
    add_index  :submissions, :lease_until
  end
end
