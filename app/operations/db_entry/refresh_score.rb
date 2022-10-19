class DbEntry::RefreshScore
  method_object %i[entry! global_average!]

  def call
    return unless @entry.stats

    new_score = @entry.anons? ?
      0 :
      Animes::WeightedScore.call(
        number_of_scores: number_of_scores,
        average_user_score: average_user_score,
        global_average: @global_average
      )

    @entry.update score_2: new_score unless @entry.score_2 == new_score
  end

private

  def number_of_scores
    @entry.stats.scores_stats.sum(&:second)
  end

  def average_user_score
    @entry.stats.scores_stats.sum do |stat|
      stat[0].to_f * stat[1] / number_of_scores
    end
  end
end
