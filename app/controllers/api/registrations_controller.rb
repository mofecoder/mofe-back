class Api::RegistrationsController < ApplicationController
  before_action :authenticate_user!

  def create
    contest = Contest.find_by!(slug: params[:contest_slug])
    if contest.end_at.past?
      render json: { error: 'コンテストは終了済みです。' }, status: :bad_request
      return
    end
    reg = Registration.find_or_initialize_by(user_id: current_user.id, contest_id: contest.id)

    if contest.closed_password.present?
      if contest.allow_open_registration && params[:open].present?
        reg.open_registration = true
      elsif params[:password].blank?
        render json: { error: '参加登録にはパスワードが必要です。' }, status: :forbidden
        return
      elsif params[:password] != contest.closed_password
        render json: { error: '参加登録パスワードが誤っています。' }, status: :forbidden
        return
      end
    end

    if reg.new_record?
      if reg.save
        render status: :created
      else
        render json: { error: reg.errors }, status: :unprocessable_entity
      end
    else
      render json: { error: 'すでに参加登録されています。' }, status: :conflict
    end
  end

  def team
    name = team_register_params[:name]
    passphrase = team_register_params[:passphrase]
    password = team_register_params[:password]

    contest = Contest.find_by!(slug: params[:contest_slug])
    if contest.end_at.past?
      render json: { error: 'コンテストは終了済みです。' }, status: :bad_request
      return
    end

    unless contest.allow_team_registration
      render json: { error: 'このコンテストはチーム参加できません。' }, status: :bad_request
    end

    reg = TeamRegistration.find_by(contest_id: contest.id, name: name)

    if reg.present?
      if reg.passphrase != passphrase
        render json: { error: 'パスフレーズが誤っています。' }, status: :forbidden
        return
      end
      if reg.team_registration_users.where(user_id: current_user.id).exists?
        render json: { error: 'すでに参加登録されています。' }, status: :conflict
        return
      end
    else
      reg = TeamRegistration.new(
        contest_id: contest.id,
        name: name,
        passphrase: passphrase,
      )
    end

    message = nil
    if contest.closed_password.present?
      if reg.new_record?
        if contest.allow_open_registration && params[:open].present?
          reg.open_registration = true
        elsif password != contest.closed_password
          error_message = password.blank? ? '参加登録にはパスワードが必要です。' : '参加登録パスワードが誤っています。'
          render json: { error: error_message }, status: :forbidden
          return
        end
      elsif reg.open_registration
        unless params[:open]
          message = '参加登録パスワードが指定されましたが、チームがオープン参加となっているためオープン参加登録されました。'
        end
      else
        if password != contest.closed_password
          error_message = password.blank? ? '指定されたチームは通常参加となっているため、オープン参加登録はできません。' : '参加登録パスワードが誤っています。'
          render json: { error: error_message }, status: :forbidden
          return
        end
      end
    end

    reg.save!
    reg.team_registration_users.create!(user_id: current_user.id)
    render json: { message: message }
  end

  def delete
    contest = Contest.find_by!(slug: params[:contest_slug])
    if contest.end_at.past?
      render json: { error: 'コンテストは終了済みです。' }, status: :bad_request
      return
    end
    reg = Registration.find_by(user_id: current_user.id, contest_id: contest.id)
    if reg.present?
      reg.destroy!
      return
    end

    team_reg = TeamRegistration.eager_load(:team_registration_users)
      .find_by(contest_id: contest.id, team_registration_users: { user_id: current_user.id })

    if team_reg.blank?
      render json: { error: '参加登録されていません' }, status: :not_found
      return
    end

    team_reg.team_registration_users.find_by(user_id: current_user.id).really_destroy!
    team_reg.team_registration_users.reload
    if team_reg.team_registration_users.empty?
      team_reg.destroy!
      render json: { message: 'チームメンバーがいなくなったため、チームを削除しました。' }
    else
      render json: { message: nil }
    end
  end

  def team_register_params
    params.permit(:contest_slug, :name, :password, :passphrase, :open)
  end
end
