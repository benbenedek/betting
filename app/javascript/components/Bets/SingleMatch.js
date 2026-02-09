import React, { useState } from 'react'

export default function SingleMatch({ match, bet, onBetUpdate, canBet, otherBets }) {
  const [saving, setSaving] = useState(false)
  const [savingPrediction, setSavingPrediction] = useState(null)

  const handlePredictionClick = async (prediction) => {
    if (!canBet || saving || !bet) return

    setSaving(true)
    setSavingPrediction(prediction)
    await onBetUpdate(bet.id, prediction)
    setSaving(false)
    setSavingPrediction(null)
  }

  const isCorrectPrediction = match.bet_score && bet?.prediction === match.bet_score
  const hasScore = match.score && match.bet_score

  return (
    <tr>
      <td style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>{match.date}</td>
      <td style={{ fontWeight: 500 }}>{match.home_team.name}</td>
      <td style={{ textAlign: 'center', color: 'var(--text-muted)' }}>-</td>
      <td style={{ fontWeight: 500 }}>{match.away_team.name}</td>
      <td style={{ textAlign: 'center' }}>
        {match.score ? (
          <span style={{ 
            background: 'var(--bg-hover)', 
            padding: '4px 8px', 
            borderRadius: '6px',
            fontWeight: 600 
          }}>
            {match.score} ({match.bet_score})
          </span>
        ) : (
          <span style={{ color: 'var(--text-muted)' }}>-</span>
        )}
      </td>

      {canBet ? (
        <td>
          <div className="bet-buttons-group">
            <button
              className={`bet-button ${bet?.prediction === '1' ? 'active' : ''} ${saving && savingPrediction === '1' ? 'saving' : ''}`}
              onClick={() => handlePredictionClick('1')}
              disabled={saving}
            >
              1
            </button>
            <button
              className={`bet-button ${bet?.prediction === 'X' ? 'active' : ''} ${saving && savingPrediction === 'X' ? 'saving' : ''}`}
              onClick={() => handlePredictionClick('X')}
              disabled={saving}
            >
              X
            </button>
            <button
              className={`bet-button ${bet?.prediction === '2' ? 'active' : ''} ${saving && savingPrediction === '2' ? 'saving' : ''}`}
              onClick={() => handlePredictionClick('2')}
              disabled={saving}
            >
              2
            </button>
          </div>
        </td>
      ) : (
        <td style={{ textAlign: 'center' }}>
          <span style={{
            display: 'inline-block',
            padding: '6px 12px',
            borderRadius: '6px',
            fontWeight: 700,
            fontSize: '1rem',
            background: hasScore 
              ? (isCorrectPrediction ? 'var(--color-success)' : 'var(--bg-hover)')
              : 'var(--bg-hover)',
            color: hasScore 
              ? (isCorrectPrediction ? 'var(--text-inverse)' : 'var(--text-primary)')
              : 'var(--text-primary)'
          }}>
            {bet?.prediction || '-'}
            {hasScore && (isCorrectPrediction ? ' ✓' : '')}
          </span>
        </td>
      )}

      {otherBets && otherBets.map((otherBet, index) => {
        const isOtherCorrect = match.bet_score && otherBet.prediction === match.bet_score
        return (
          <td key={index} style={{ textAlign: 'center' }}>
            <span style={{
              display: 'inline-block',
              padding: '4px 10px',
              borderRadius: '6px',
              fontWeight: 600,
              fontSize: '0.9rem',
              background: hasScore 
                ? (isOtherCorrect ? 'var(--color-success)' : 'var(--bg-hover)')
                : 'var(--bg-hover)',
              color: hasScore 
                ? (isOtherCorrect ? 'var(--text-inverse)' : 'var(--text-secondary)')
                : 'var(--text-secondary)'
            }}>
              {otherBet.prediction}
            </span>
          </td>
        )
      })}
    </tr>
  )
}
