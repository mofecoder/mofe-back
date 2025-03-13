# frozen_string_literal: true

class ProblemBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :difficulty

  field :score do |problem|
    problem.testcase_sets.to_a.sum(&:points)
  end

  view :unset_problem do
    field :writer_user do |problem|
      problem.writer_user.name
    end
  end

  view :problem do
    include_view :unset_problem
    fields :slug

    field :contest do |problem|
      {
        name: problem.contest.name,
        slug: problem.contest.slug
      }
    end
  end

  view :problem_detail do
    include_view :unset_problem
    fields :slug, :execution_time_limit,
           :submission_limit_1, :submission_limit_2,
           :statement, :constraints, :partial_scores,
           :input_format, :output_format, :checker_path, :samples

    field :testers do |problem|
      problem.testers.map(&:name)
    end

    association :contest, blueprint: ContestBlueprint
  end

  # TODO: Blueprint for Contest Task
  view :contest_task_common do
    fields :slug, :position
  end

  view :contest_task do
    include_view :contest_task_common
    field :accepted do |problem, options|
      options[:accepted].include?(problem.id)
    end
  end

  view :task_detail do
    include_view :contest_task_common
  end
end
