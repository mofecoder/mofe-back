class Api::StandingsController < ApplicationController
  def index
    # @type [Contest]
    contest = Contest.find_by!(slug: params[:contest_slug])
    penalty_time = contest.penalty_time
    started_at = contest.start_at
    submissions = Submission.joins(problem: :contest).preload(:user).preload(:problem)
                        .where('contests.slug': params[:contest_slug])
                        .where(created_at: started_at..contest.end_at)
                        .select('user_id, problem_id, status, point, submissions.created_at')
                        .order(created_at: :asc)

    # @type [Hash]
    problems = Problem.joins(:contest).preload(:testcase_sets, :tester_relations).preload(contest: :contest_admins)
                   .where('contests.slug': params[:contest_slug])
                   .order(:position)
                   .map { |p| [p.id, p] }.to_h
    show_problems = contest.is_writer_or_tester(current_user) || started_at.past?

    require 'set'

    admins = Set.new(contest.contest_admins.pluck(:user_id) + User.where(role: 'admin').pluck(:id))

    # @type [Hash]
    users = {}
    user_table = {}

    reg = contest.registrations.includes(:user)

    if params.include?(:exclude_open)
      reg.where!(open_registration: false)
    end

    reg.each do |registration|
      users[registration.user_id] = []
      user_table[registration.user_id] = registration.user
    end

    #@type [Hash]
    problem_score_table = {}
    problem_writers = {}
    problems.each do |problem|
      problem_score_table[problem[0]] = problem[1].testcase_sets.to_a.sum(&:points)
      problem_writers[problem[0]] = Set.new(problem[1].tester_relations.pluck(:tester_user_id) + [problem[1].writer_user_id])
    end

    first_ac = problems.to_a.map { |d| [d[0], [nil, nil]] }.to_h
    submissions.each do |sub|
      next if problem_writers[sub.problem_id].include?(sub.user_id)
      next if admins.include?(sub.user_id)
      if users[sub.user_id]
        users[sub.user_id] << sub
        first_ac_time = first_ac[sub.problem.id][0]
        if sub.status == 'AC' && first_ac_time.nil?
          first_ac[sub.problem.id] = [sub.created_at, sub.user.id]
        end
      end
    end

    if contest.icpc?
      res, solved, trying = icpc_standings(users, user_table, problems, problem_score_table, started_at, penalty_time)
    else
      res = []
      solved = problems.to_a.map { |d| [d[0], 0] }.to_h
      trying = problems.to_a.map { |d| [d[0], 0] }.to_h
      # @type [Array<Submission>] value
      users.each do |user_id, value|
        ls = []
        group = value.group_by { |p| p.problem_id }
        score_sum = 0
        time_max = 0
        penalty = 0
        problems.each do |id, problem|
          # @type [Array<Submission>] s
          s = group[id]
          if s.nil? || user_id == problem.writer_user_id
            ls << {}
            next
          end
          tmp = aggregate(s)
          if tmp.nil?
            ls << {}
            next
          end
          tmp[:time] = (tmp[:time] - started_at).to_i

          if tmp[:score] > 0
            penalty += tmp[:penalty]
            time_max = tmp[:time] if tmp[:time] > time_max
            score_sum += tmp[:score]

            tmp[:penalty] = nil if tmp[:penalty] == 0
            solved[id] += 1 if tmp[:score] == problem_score_table[problem.id]
          elsif tmp[:penalty] > 0
            tmp = {
              penalty: tmp[:penalty]
            }
            trying[id] += 1
          else
            tmp = {
              penalty: 0
            }
          end

          ls << tmp
        end

        user = user_table[user_id]

        res << {
          user: {
            name: user.name,
            atcoder_id: user.atcoder_id,
            atcoder_rating: user.atcoder_rating
          },
          result: {
            score: score_sum,
            time: time_max + penalty * penalty_time,
            penalty: penalty == 0 ? nil : penalty
          },
          problems: show_problems ? ls : []
        }
      end
    end

    problem_res = []
    if show_problems
      # @type [Problem] task
      problems.each do |id, task|
        fa = first_ac[id]
        user = fa[1] ? user_table[fa[1]] : nil
        problem_res << {
          name: task.has_permission?(current_user) ? task.name : nil,
          slug: task.slug,
          position: task.position,
          solved: solved[id],
          tried: solved[id] + trying[id],
          first_accept: user ? {
            time: (fa[0] - started_at).to_i,
            user: {
              name: user.name,
              atcoder_id: user.atcoder_id,
              atcoder_rating: user.atcoder_rating
            }
          } : nil
        }
      end
    end

    res.sort! do |a, b|
      if a[:result][:score] == b[:result][:score]
        a[:result][:time] <=> b[:result][:time]
      else
        b[:result][:score] <=> a[:result][:score]
      end
    end

    if res.length > 0
      res[0][:rank] = 1
      1.upto(res.length - 1) do |i|
        if res[i - 1][:result][:score] == res[i][:result][:score] &&
            res[i - 1][:result][:time] == res[i][:result][:time]
          res[i][:rank] = res[i - 1][:rank]
        else
          res[i][:rank] = i + 1
        end
      end
    end

    render json: {
        problems: problem_res,
        standings: res
    }
  end

  private

  def icpc_standings(users, user_table, problems, problem_score_table, started_at, penalty_time)
    res = []
    solved = problems.to_a.map { |d| [d[0], 0] }.to_h
    trying = problems.to_a.map { |d| [d[0], 0] }.to_h
    # @type [Array<Submission>] value
    users.each do |user_id, value|
      ls = []
      group = value.group_by { |p| p.problem_id }
      score_sum = 0
      time_sum = 0
      penalty = 0
      problems.each do |id, problem|
        # @type [Array<Submission>] s
        s = group[id]
        if s.nil? || user_id == problem.writer_user_id
          ls << {
            is_in_progress: false
          }
          next
        end
        tmp = aggregate(s)
        is_in_progress = s.any? do |sub|
          %w(WJ WR CP WIP).include?(sub.status)
        end
        if tmp.nil?
          ls << {
            is_in_progress: is_in_progress
          }
          next
        end
        tmp[:time] = (tmp[:time] - started_at).to_i

        if tmp[:score] == problem_score_table[problem.id]
          penalty += tmp[:penalty]
          time_sum +=  tmp[:time]
          score_sum += 1

          tmp[:penalty] = nil if tmp[:penalty] == 0
          solved[id] += 1
        elsif tmp[:penalty] > 0
          tmp = {
            penalty: tmp[:penalty]
          }
          trying[id] += 1
        else
          tmp = {
            penalty: 0
          }
        end

        tmp[:is_in_progress] = is_in_progress
        ls << tmp
      end

      user = user_table[user_id]

      res << {
        user: {
          name: user.name,
          atcoder_id: user.atcoder_id,
          atcoder_rating: user.atcoder_rating
        },
        result: {
          score: score_sum,
          time: time_sum + penalty * penalty_time,
          penalty: penalty == 0 ? nil : penalty
        },
        problems: ls
      }
    end

    [res, solved, trying]
  end

  # @param [Array<Submission>] submissions
    # @return [Hash, nil]
    def aggregate(submissions)
      confirmed_pena = 0
      now_pena = 0
      max_point = -1
      time = nil

      submissions.each do |sub|
        if %w(WJ WR CP WIP).include?(sub.status)
          next
        end
        if %w(IE CE).include?(sub.status)
          next
        end
        if %w(WA RE OLE MLE TLE).include?(sub.status)
          now_pena += 1
        end
        score = sub.point || 0
        if score > max_point
          max_point = score
          confirmed_pena = now_pena
          time = sub.created_at
        end
      end

      if max_point == 0
        confirmed_pena = now_pena
      end

      max_point == -1 ? nil : {
          score: max_point,
          time: time,
          penalty: confirmed_pena
      }
    end
end
