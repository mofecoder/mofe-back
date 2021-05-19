class Api::PasswordsController < DeviseTokenAuth::PasswordsController
  def create
    user = User.find_by(email: params[:email])
    user&.send_reset_password_instructions
    render json: { message: 'パスワードリセットメールを送信しました。' }
  end

  def update
    user = User.reset_password_by_token(update_params)
    render json: { message: 'パスワードを変更しました。' }
  end

  private

  def update_params
    params.require(:user).permit(:password, :password_confirmation, :reset_password_token)
  end
end
