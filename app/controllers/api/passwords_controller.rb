class Api::PasswordsController < DeviseTokenAuth::PasswordsController
  # メールの大量送信とリセットトークンの総当たりを防ぐ (IP 単位)
  rate_limit to: 5, within: 1.hour, only: :create, name: 'create', with: :render_rate_limited
  rate_limit to: 10, within: 1.hour, only: :update, name: 'update', with: :render_rate_limited

  def create
    user = User.find_by(email: params[:email])
    user&.send_reset_password_instructions
    render json: { message: 'パスワードリセットメールを送信しました。' }
  end

  def update
    user = User.reset_password_by_token(update_params)
    if user.errors.empty?
      render json: { message: 'パスワードを変更しました。' }
    else
      render_validation_error(user, status: :unprocessable_entity)
    end
  end

  private

  def render_rate_limited
    render_api_error('リクエストが多すぎます。しばらく待ってからやり直してください。', status: :too_many_requests)
  end

  def update_params
    params.require(:user).permit(:password, :password_confirmation, :reset_password_token)
  end
end
