class Api::TopPageController < ApplicationController
  def index
    render json: {
      contests: contests,
      posts: (current_user&.admin? ? Post.all : Post.where(public_status: 'public')).order(updated_at: :desc).limit(5),
      creating: creating
    }
  end

  private

  def contests
    now = DateTime::now
    fields = %i(slug name kind start_at end_at)
    contests = Contest.all.select(*fields)
    during = contests.where('`start_at` <= ? AND `end_at` > ?', now, now).where(permanent: false).order(:end_at)
    future = contests.where('`start_at` > ?', now).where(permanent: false).order(:start_at)
    past = contests.where('`end_at` <= ?', now).where(permanent: false).order(end_at: :desc).limit(10)
    unless current_user&.admin?
      during = during.where.not(kind: 'private')
      future = future.where.not(kind: 'private')
      past = past.where.not(kind: 'private')
    end

    (during + future + past).to_a[0, 10]
  end

  def creating
    if current_user.blank?
      return nil
    end

    problems = Problem
                 .left_joins(:contest)
                 .where(writer_user_id: current_user.id)
                 .where('contests.end_at > ? OR contests.id IS NULL', DateTime::now)

    ActiveModelSerializers::SerializableResource.new(
      problems,
      each_serializer: ProblemSerializer,
      adapter: :attributes
    ).serializable_hash
  end
end
