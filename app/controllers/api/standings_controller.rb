class Api::StandingsController < ApplicationController
  def index
    # TODO: ペナルティを設定できるようにする
    contest = Contest.find_by!(slug: params[:contest_slug])
    started_at = contest.start_at
    submits = Submit.joins(problem: :contest).includes(:user)
                  .where('contests.slug': params[:contest_slug])
                  .where(created_at: started_at..contest.end_at)
                  .select('user_id, problem_id, status, point, submits.created_at')
                  .order(created_at: :asc)

    problems = Problem.joins(:contest)
                   .where('contests.slug': params[:contest_slug])
                   .map { |p| [p.id, p] }.to_h

    # @type [Hash]
    users = {}
    submits.each do |submit|
      users[submit.user_id] = [] if users[submit.user_id].nil?
      users[submit.user_id] << submit
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
      problems.each do |id, _|
        # @type [Array<Submit>] s
        s = group[id]
        if s.nil?
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

        ls << tmp
      end

      res << {
          user_name: value[0].user.name,
          result: {
              score: score_sum,
              time: time_max,
              penalty: penalty == 0 ? nil : penalty
          },
          problems: ls
      }
    end

    problem_res = []
    # @type [Problem] task
    problems.each do |id, task|
      problem_res << {
          name: task.name,
          slug: task.slug,
          position: task.position,
          solved: solved[id],
          tried: solved[id] + trying[id]
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
        if submit.point > max_point
          max_point = submit.point
          confirmed_pena = now_pena
          time = submit.created_at
        end
      end

      max_point == -1 ? nil : {
          score: max_point,
          time: time,
          penalty: confirmed_pena
      }
    end
end
