class Api::TopPageController < Api::ApplicationController
  def index
    authorize [:api, :top_page], :index?

    render json: {
      contests: contests,
      posts: policy_scope([:api, Post]).order(updated_at: :desc).limit(5),
      creating: creating
    }
  end

  private

  def contests
    now = DateTime::now
    fields = %i(slug name kind start_at end_at)
    contests = policy_scope([:api, Contest]).select(*fields)
    during = contests.where('`start_at` <= ? AND `end_at` > ?', now, now).where(permanent: false).order(:end_at)
    future = contests.where('`start_at` > ?', now).where(permanent: false).order(:start_at)
    past = contests.where('`end_at` <= ?', now).where(permanent: false).order(end_at: :desc).limit(10)

    (during + future + past).to_a[0, 10]
  end

  def creating
    if current_user.blank?
      return nil
    end

    problem_ids_writer = Problem
                 .where(writer_user_id: current_user.id)
                 .pluck(:id)
    problem_ids_tester = TesterRelation
                           .where(tester_user_id: current_user.id)
                           .where(approved: true)
                           .pluck(:problem_id)

    problems = Problem.left_joins(:contest)
           .where(id: problem_ids_writer + problem_ids_tester)
           .where('contests.end_at > ? OR contests.id IS NULL', DateTime::now)

    ActiveModelSerializers::SerializableResource.new(
      problems,
      each_serializer: ProblemSerializer,
      adapter: :attributes
    ).serializable_hash
  end
end
