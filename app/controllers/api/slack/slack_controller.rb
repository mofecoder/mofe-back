class Api::Slack::SlackController < ApplicationController
  def add_writer
    if params[:token] != Rails.application.credentials.slack[:verification_token]
      render status: 401
      return
    end
    puts 'Header:'
    p request.headers
    puts 'Text:'
    p params[:text]

    #@type [Array<String>]
    payload = params[:text].split(' ')
    if payload.length != 2
      render json: { text: 'Usage: /register_user [user_id] [writer_request_code]' }
      return
    end

    user = User.find_by(name: payload[0])
    if user.blank?
      render json: { text: 'ユーザが見つかりませんでした' }
      return
    end

    if user.role != 'member'
      render json: { text: "#{user.name} さんは権限 '#{user.role}' であるため writer として登録できません" }
      return
    end

    if user.writer_request_code != payload[1]
      render json: { text: 'Writer リクエストコードが間違っています' }
      return
    end

    user.role = 'writer'
    if user.save
      render json: { text: "#{user.name} さんを writer として登録しました！" }
    else
      render json: { text: "writer 登録に失敗しました。admin に問い合わせてください。\nerror: #{user.error}" }
    end
  end
end
