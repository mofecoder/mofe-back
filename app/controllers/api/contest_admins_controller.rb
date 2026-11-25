class Api::ContestAdminsController < Api::ApplicationController
  before_action :authenticate_user!
  before_action :authorize_manage_admins!
  before_action :set_contest

  def create
    names = Array(params[:user_names]).map { |name| name.to_s.strip }.reject(&:empty?).uniq

    if names.empty?
      render json: { error: 'ユーザ名を指定してください。' }, status: :bad_request
      return
    end

    # DB の照合順序で大文字小文字を区別せず一致する場合があるため、小文字で引き当てる
    users = User.where(name: names).index_by { |user| user.name.downcase }
    admin_user_ids = @contest.contest_admins.where(user_id: users.values.map(&:id)).pluck(:user_id).to_set

    added = []
    errors = []
    names.each do |name|
      user = users[name.downcase]
      if user.nil?
        errors << { user_name: name, error: '指定されたユーザ名のユーザは存在しません。' }
      elsif admin_user_ids.include?(user.id)
        errors << { user_name: name, error: '指定されたユーザは既にコンテスト管理者として追加されています。' }
      else
        ContestAdmin.create!(contest_id: @contest.id, user_id: user.id)
        admin_user_ids << user.id
        added << name
      end
    end

    render json: { added: added, errors: errors }
  end

  def destroy
    user = User.find_by!(name: params[:user_name])
    @contest.contest_admins.find_by!(user_id: user.id).discard
  end

  private

  # コンテストを引く前に認可する（未知の slug でも 403 を返す現行挙動を維持）
  def authorize_manage_admins!
    authorize [:api, Contest], :manage_admins?
  end

  def set_contest
    @contest = Contest.find_by!(slug: params[:contest_slug])
  end
end
