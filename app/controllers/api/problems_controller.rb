class Api::ProblemsController < Api::ApplicationController
  before_action :authenticate_user!

  # GET /problems
  def index
    authorize [:api, Problem]

    problems = policy_scope([:api, Problem]).includes(:writer_user, :contest).order(id: :desc)

    render json: problems
  end

  # GET /problems/1
  def show
    problem = Problem.includes(:testers).find(params[:id])
    authorize [:api, problem]

    render json: problem, serializer: ProblemDetailSerializer
  end

  # POST /problems
  def create
    authorize [:api, Problem]

    ActiveRecord::Base.transaction do
      @problem = Problem.new(problem_params)
      @problem.uuid = SecureRandom.uuid
      @problem.writer_user_id = current_user.id
      @problem.checker_path = 'checker_sources/wcmp.cpp'
      @problem.submission_limit_1 = 5
      @problem.submission_limit_2 = 60

      if @problem.save
        @problem.testcase_sets.create(
            name: 'sample',
            points: 0,
            is_sample: true
        )
        @problem.testcase_sets.create(
            name: 'all',
            points: 100,
            is_sample: false
        )

        render json: @problem, serializer: ProblemDetailSerializer, status: :created
      else
        render json: @problem.errors, status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /problems/1
  def update
    problem = Problem.find(params[:id])
    authorize [:api, problem]

    if problem.update(problem_edit_params)
      render json: problem, serializer: ProblemDetailSerializer
    else
      render json: problem.errors, status: :unprocessable_entity
    end
  end

  def download_checker
    problem = Problem.find(params[:problem_id])
    authorize [:api, problem], :download_checker?

    checker_data = Utils::GoogleCloudStorageClient::get_source(problem.checker_path)

    send_data(checker_data, type: 'text/x-c')
  end

  def update_checker
    problem = Problem.find(params[:problem_id])
    authorize [:api, problem], :update_checker?

    if params[:type].nil?
      file_path = "./tmp/#{SecureRandom.uuid}.zip"
      # @type [ActionDispatch::Http::UploadedFile]
      file = params[:file]

      path = "checker_sources/#{problem.uuid}"

      Utils::GoogleCloudStorageClient::upload_source(path, file.read)

      FileUtils.rm_f file_path

      problem.checker_path = path
    else
      problem.checker_path = "checker_sources/#{params[:type]}"
    end

    problem.save
  end

  private

  # Only allow a trusted parameter "white list" through.
  def problem_edit_params
    params.require(:problem)
          .permit(:name, :difficulty, :execution_time_limit, :statement,
                  :constraints, :partial_scores, :input_format, :output_format,
                  :submission_limit_1, :submission_limit_2)
  end

  def problem_params
    params.require(:problem).permit(
      :name, :difficulty, :statement, :constraints, :partial_scores, :input_format, :output_format, :execution_time_limit
    )
  end
end
