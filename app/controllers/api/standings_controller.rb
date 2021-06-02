class Api::StandingsController < ApplicationController
  def index
    # @type [Contest]
    contest = Contest.includes(registrations: :user).find_by!(slug: params[:contest_slug])
    penalty_time = contest.penalty_time
    started_at = contest.start_at
    submits = Submit.joins(problem: :contest).includes(:user)
                  .where('contests.slug': params[:contest_slug])
                  .where(created_at: started_at..contest.end_at)
                  .select('user_id, problem_id, status, point, submits.created_at')
                  .order(created_at: :asc)

    problems = Problem.joins(:contest, :testcase_sets, :tester_relations)
                   .where('contests.slug': params[:contest_slug])
                   .order(:position)
                   .map { |p| [p.id, p] }.to_h

    require 'set'

    writers = Set.new(contest.problems.pluck(:writer_user_id) +
        TesterRelation.where(problem: contest.problems).pluck(:tester_user_id))

    # @type [Hash]
    users = {}
    user_table = {}
    contest.registrations.each do |registration|
      users[registration.user_id] = []
      user_table[registration.user_id] = registration.user
    end

    #@type [Hash]
    problem_score_table = {}
    problems.each do |problem|
      problem_score_table[problem[0]] = problem[1].testcase_sets.to_a.sum(&:points)
    end

    first_ac = problems.to_a.map { |d| [d[0], [nil, nil]] }.to_h
    submits.each do |submit|
      next if writers.include?(submit.user_id)
      unless users[submit.user_id].nil?
        users[submit.user_id] << submit
        first_ac_time = first_ac[submit.problem.id][0]
        if first_ac_time.nil?
          first_ac[submit.problem.id] = [submit.created_at, submit.user.id]
        end
      end
    end

    res = []
    solved = problems.to_a.map { |d| [d[0], 0] }.to_h
    trying = problems.to_a.map { |d| [d[0], 0] }.to_h
    # @type [Array<Submit>] value
    users.each do |user_id, value|
      ls = []
      group = value.group_by { |p| p.problem_id }
      score_sum = 0
      time_max = 0
      penalty = 0
      problems.each do |id, problem|
        # @type [Array<Submit>] s
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
          problems: ls
      }
    end

    problem_res = []
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

    # @param [Array<Submit>] submits
    # @return [Hash, nil]
    def aggregate(submits)
      confirmed_pena = 0
      now_pena = 0
      max_point = -1
      time = nil

      submits.each do |submit|
        if %w(WJ WR IE CE).include?(submit.status)
          next
        end
        if %w(WA RE OLE MLE TLE).include?(submit.status)
          now_pena += 1
        end
        score = submit.point || 0
        if score > max_point
          max_point = score
          confirmed_pena = now_pena
          time = submit.created_at
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
