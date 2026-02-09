import React, { useState } from 'react'

export default function MatchCard({ match, bet, onBetUpdate, canBet, otherBets }) {
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

  // Group other bets by prediction
  const groupedBets = otherBets ? otherBets.reduce((acc, bet) => {
    if (!acc[bet.prediction]) acc[bet.prediction] = []
    acc[bet.prediction].push(bet.user)
    return acc
  }, {}) : {}

  return (
    <div className="match-card">
      {/* Header with date and score */}
      <div className="match-card-header">
        <span className="match-card-date">{match.date}</span>
        {hasScore && (
          <span className="match-card-score">
            {match.score} ({match.bet_score})
          </span>
        )}
      </div>

      {/* Match Teams */}
      <div className="match-card-body">
        <div className="match-teams">
          <div className="match-team">
            <span style={{
              background: 'var(--color-primary)',
              color: 'white',
              fontSize: '0.65rem',
              fontWeight: 600,
              padding: '2px 6px',
              borderRadius: 'var(--radius-sm)',
              marginLeft: '8px',
            }}>
              בית
            </span>
            <span style={{ fontWeight: 600 }}>{match.home_team.name}</span>
          </div>
          <div className="match-vs">VS</div>
          <div className="match-team">
            <span style={{
              background: 'var(--text-secondary)',
              color: 'white',
              fontSize: '0.65rem',
              fontWeight: 600,
              padding: '2px 6px',
              borderRadius: 'var(--radius-sm)',
              marginLeft: '8px',
            }}>
              חוץ
            </span>
            <span style={{ fontWeight: 600 }}>{match.away_team.name}</span>
          </div>
        </div>
      </div>

      {/* Betting Buttons or Prediction Display */}
      <div className="match-card-footer">
        {canBet ? (
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
        ) : (
          <div className="match-user-prediction">
            <div className="match-prediction-label">ההימור שלך</div>
            <div className={`match-prediction-value ${hasScore ? (isCorrectPrediction ? 'correct' : 'incorrect') : ''}`}>
              {bet?.prediction || '-'}
              {hasScore && (isCorrectPrediction ? ' ✓' : ' ✗')}
            </div>
          </div>
        )}
      </div>

      {/* Other Users' Bets - Grouped by Prediction */}
      {otherBets && otherBets.length > 0 && (
        <OtherBetsDisplay 
          groupedBets={groupedBets} 
          correctPrediction={match.bet_score}
          hasScore={hasScore}
        />
      )}
    </div>
  )
}

function OtherBetsDisplay({ groupedBets, correctPrediction, hasScore }) {
  const predictions = ['1', 'X', '2']
  
  return (
    <div style={{
      borderTop: '1px solid var(--bg-hover)',
      padding: 'var(--space-md)',
      background: 'var(--bg-primary)',
    }}>
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(3, 1fr)',
        gap: 'var(--space-sm)',
      }}>
        {predictions.map(prediction => {
          const users = groupedBets[prediction] || []
          const isCorrect = hasScore && prediction === correctPrediction
          const isEmpty = users.length === 0
          
          return (
            <div 
              key={prediction}
              style={{
                background: isEmpty 
                  ? 'transparent' 
                  : hasScore 
                    ? (isCorrect ? 'rgba(16, 185, 129, 0.15)' : 'rgba(239, 68, 68, 0.08)')
                    : 'var(--bg-card)',
                borderRadius: 'var(--radius-md)',
                padding: 'var(--space-sm)',
                border: isEmpty 
                  ? '1px dashed var(--text-muted)' 
                  : hasScore
                    ? (isCorrect ? '2px solid var(--color-success)' : '1px solid var(--bg-hover)')
                    : '1px solid var(--bg-hover)',
                opacity: isEmpty ? 0.4 : 1,
                transition: 'var(--transition-fast)',
              }}
            >
              {/* Prediction Header */}
              <div style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: 'var(--space-xs)',
                marginBottom: 'var(--space-xs)',
              }}>
                <span style={{
                  fontWeight: 700,
                  fontSize: '1.1rem',
                  color: hasScore 
                    ? (isCorrect ? 'var(--color-success)' : 'var(--text-secondary)')
                    : 'var(--color-primary)',
                }}>
                  {prediction}
                </span>
                {hasScore && isCorrect && (
                  <span style={{ color: 'var(--color-success)', fontSize: '0.9rem' }}>✓</span>
                )}
                {users.length > 0 && (
                  <span style={{
                    background: hasScore 
                      ? (isCorrect ? 'var(--color-success)' : 'var(--text-muted)')
                      : 'var(--color-primary)',
                    color: 'white',
                    fontSize: '0.7rem',
                    fontWeight: 600,
                    padding: '1px 6px',
                    borderRadius: 'var(--radius-full)',
                    minWidth: '18px',
                    textAlign: 'center',
                  }}>
                    {users.length}
                  </span>
                )}
              </div>
              
              {/* User Names */}
              <div style={{
                display: 'flex',
                flexDirection: 'column',
                gap: '2px',
                alignItems: 'center',
              }}>
                {users.length === 0 ? (
                  <span style={{ 
                    fontSize: '0.7rem', 
                    color: 'var(--text-muted)',
                  }}>
                    —
                  </span>
                ) : (
                  users.map((user, idx) => (
                    <span 
                      key={idx}
                      style={{
                        fontSize: '0.75rem',
                        color: hasScore 
                          ? (isCorrect ? 'var(--color-success)' : 'var(--text-secondary)')
                          : 'var(--text-primary)',
                        fontWeight: isCorrect ? 500 : 400,
                        whiteSpace: 'nowrap',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        maxWidth: '100%',
                      }}
                    >
                      {user.name}
                    </span>
                  ))
                )}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
