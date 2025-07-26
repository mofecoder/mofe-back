class Api::Internal::UsersController < ApplicationController
  def update
    user = User.find_or_initialize_by(uid: user_params[:uid])

    if user.new_record?
      unless user_params[:email].present? && user_params[:name].present?
        render json: { error: 'Invalid parameters' }, status: :bad_request
        return
      end
      unless user.update(user_params)
        render json: { error: user.errors }, status: :unprocessable_entity
        return
      end
    end

    render json: {
      status: 'success',
      user: user.as_json(only: serialize_fields)
    }, status: :ok
  end

  private
  def user_params
    params.require(:user).permit(:uid, :email)
  end

  def serialize_fields
    [:id, :name, :email, :role, :atcoder_id, :atcoder_rating]
  end
end
