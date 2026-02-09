class Api::V1::BetsController < Api::V1::BaseController
  # PATCH /api/v1/bets/:id
  def update
    @bet = Bet.find(params[:id])

    # Verify the bet belongs to current user
    unless @bet.user_bet.user.id == current_user.id
      return render json: { error: 'Unauthorized' }, status: :forbidden
    end

    # Validate prediction value
    prediction = params[:prediction]
    unless %w[1 2 X].include?(prediction)
      return render json: { error: 'Invalid prediction. Must be 1, X, or 2' }, status: :unprocessable_entity
    end

    # Check if betting is still allowed for this match
    unless @bet.match.can_still_bet_on_match?
      return render json: { error: 'Betting is closed for this match' }, status: :forbidden
    end

    # Update the prediction
    @bet.update!(prediction: prediction)

    render json: {
      id: @bet.id,
      match_id: @bet.match_id,
      prediction: @bet.prediction
    }
  end
end
