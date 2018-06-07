class ScoreLogCalculation
  # This class to calculation score of evaluation log
  # This will be called after insert score logs
  
  def initialize(evaluation_log)
    @evaluation_log = evaluation_log
    @score_groups = {}
  end
  
  def calc_score_and_save
    do_calc_score
  end
  
  private
  
  def do_calc_score
    @logs = find_logs
    @max_score = 0
    @total_score = 0
    @weighted_score = 0
    
    # sum max score
    @logs.each do |log|
      @max_score += log.max_score.to_f
      @total_score += log.actual_score.to_f
    end
    
    # calc score each question base by total max_score
    @logs.each do |log|
      log.weighted_score = log.actual_score.to_f/@max_score*100.0
      log.save
    end
    
    @evaluation_log.score = @total_score
    @evaluation_log.weighted_score = @total_score/@max_score*100.0
    @evaluation_log.save
  end
  
  def find_logs
    logs = EvaluationScoreLog.only_question
    return logs.find_by_evaluation_log(@evaluation_log.id).all
  end
  
end