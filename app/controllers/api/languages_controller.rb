# frozen_string_literal: true

# 言語一覧（S8）。認証なしで、inactive な言語（過去の提出の表示用）も含めて返す。
class Api::LanguagesController < Api::ApplicationController
  def index
    authorize [:api, :language], :index?

    render json: Language.all
  end
end
