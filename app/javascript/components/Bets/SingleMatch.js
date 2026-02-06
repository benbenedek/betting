import React, { useState } from 'react'

export default function SingleMatch({ match, bet, onBetUpdate, canBet, otherBets }) {
  const [saving, setSaving] = useState(false)

  const handlePredictionClick = async (prediction) => {
    if (!canBet || saving || !bet) return

    setSaving(true)
    await onBetUpdate(bet.id, prediction)
    setSaving(false)
  }

  const isCorrectPrediction = match.bet_score && bet?.prediction === match.bet_score

  return (
    <tr>
      <td className="hidden-sm hidden-xs">{match.date}</td>
      <td>{match.home_team.name}</td>
      <td>-</td>
      <td>{match.away_team.name}</td>
      <td>
        {match.score ? (
          <>
            {match.score} ({match.bet_score})
          </>
        ) : (
          '-'
        )}
      </td>

      {canBet ? (
        <td>
          <div className="btn-group" data-toggle="buttons">
            <button
              className={`btn btn-primary btn-xs ${bet?.prediction === '2' ? 'active' : ''}`}
              onClick={() => handlePredictionClick('2')}
              disabled={saving}
            >
              2
            </button>
            <button
              className={`btn btn-primary btn-xs ${bet?.prediction === 'X' ? 'active' : ''}`}
              onClick={() => handlePredictionClick('X')}
              disabled={saving}
            >
              X
            </button>
            <button
              className={`btn btn-primary btn-xs ${bet?.prediction === '1' ? 'active' : ''}`}
              onClick={() => handlePredictionClick('1')}
              disabled={saving}
            >
              1
            </button>
          </div>
        </td>
      ) : (
        <td className={isCorrectPrediction ? 'success' : 'info'}>
          {bet?.prediction || '-'}
        </td>
      )}

      {otherBets && otherBets.map((otherBet, index) => {
        const isOtherCorrect = match.bet_score && otherBet.prediction === match.bet_score
        return (
          <td key={index} className={isOtherCorrect ? 'success' : 'info'}>
            {otherBet.prediction}
          </td>
        )
      })}

      <td>
        {saving && <span className="label label-info">שומר...</span>}
      </td>
    </tr>
  )
}
