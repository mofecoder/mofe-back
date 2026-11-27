# デバッグ提出（テストケースごとの出力の保存）のための列を追加する。
# - submissions.output_capture: 何を保存するか（NULL は保存しない、'all' はデバッグ提出）。worker はこの値だけに従う。
# - testcase_results.outputs: 保存した出力のメタ情報（JSON の文字列）。
#   本番の DB は MariaDB 10.0 で json 型が無い（10.2.7 から）ので text にする。
class AddOutputCapture < ActiveRecord::Migration[8.1]
  def change
    add_column :submissions, :output_capture, :string, limit: 16, null: true
    add_column :testcase_results, :outputs, :text, null: true
  end
end
