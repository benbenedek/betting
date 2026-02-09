import React, { useState, useEffect, useCallback } from 'react'
import { useParams, Link } from 'react-router-dom'
import api from '../../lib/api'
import SingleMatch from './SingleMatch'
import MatchCard from './MatchCard'
import { LoadingSpinner } from '../BettingApp'

export default function BetsList({ leagueId: propLeagueId, fixtureNumber: propNumber, csrfToken }) {
  const params = useParams()
  const leagueId = propLeagueId || params.leagueId
  const fixtureNumber = propNumber || params.fixtureNumber

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [fixture, setFixture] = useState(null)
  const [matches, setMatches] = useState([])
  const [userBets, setUserBets] = useState(null)
  const [allFixtures, setAllFixtures] = useState([])
  const [currentUser, setCurrentUser] = useState(null)
  const [otherUsersBets, setOtherUsersBets] = useState(null)
  const [showOtherBets, setShowOtherBets] = useState(false)
  const [dropdownOpen, setDropdownOpen] = useState(false)

  const loadFixture = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)

      let data
      if (leagueId && fixtureNumber) {
        data = await api.getFixture(leagueId, fixtureNumber)
      } else {
        data = await api.getCurrentFixture()
      }

      setFixture(data.fixture)
      setMatches(data.matches)
      setUserBets(data.user_bets)
      setAllFixtures(data.all_fixtures)
      setCurrentUser(data.current_user)

      // If betting is closed, try to load other users' bets
      if (!data.fixture.can_still_bet) {
        try {
          const allBetsData = await api.getAllBets(data.fixture.id)
          setOtherUsersBets(allBetsData.user_bets)
        } catch (e) {
          // Ignore error if betting is still open
        }
      }
    } catch (err) {
      // Check if this is a "Fixture not found" error (404)
      if (err.message === 'Fixture not found') {
        // Set fixture to null to trigger the "fixture not found" UI
        setFixture(null)
      } else {
        setError(err.message)
      }
      // Even if fixture fails, try to get current user for admin check
      try {
        const userData = await api.getCurrentUser()
        setCurrentUser(userData)
      } catch (e) {
        // Ignore - user might not be logged in
      }
    } finally {
      setLoading(false)
    }
  }, [leagueId, fixtureNumber])

  useEffect(() => {
    loadFixture()
  }, [loadFixture])

  const handleBetUpdate = async (betId, prediction) => {
    try {
      const updatedBet = await api.updateBet(betId, prediction, csrfToken)

      // Update local state
      setUserBets(prev => ({
        ...prev,
        bets: prev.bets.map(bet =>
          bet.id === updatedBet.id ? updatedBet : bet
        )
      }))
    } catch (err) {
      alert(`שגיאה: ${err.message}`)
    }
  }

  const handleToggleOpen = async () => {
    if (!currentUser?.is_admin || !fixture) return

    try {
      await api.toggleFixtureOpen(fixture.id, !fixture.is_open, csrfToken)
      loadFixture() // Reload to get updated state
    } catch (err) {
      alert(`שגיאה: ${err.message}`)
    }
  }

  const handleRunMigration = async () => {
    if (!currentUser?.is_admin) return

    const migrationLeagueId = fixture?.league_id || leagueId || 10
    const migrationNumber = fixture?.number || fixtureNumber

    if (!migrationNumber) {
      alert('לא ניתן להריץ מיגרציה ללא מספר מחזור')
      return
    }

    try {
      await api.runMigration(migrationLeagueId, migrationNumber, csrfToken)
      alert('המיגרציה הושלמה בהצלחה')
      loadFixture() // Reload to get updated data
    } catch (err) {
      alert(`שגיאה: ${err.message}`)
    }
  }

  if (loading) {
    return <LoadingSpinner text="טוען משחקים..." />
  }

  if (error) {
    return <div className="alert alert-error">{error}</div>
  }

  if (!fixture) {
    return (
      <div style={{ padding: '16px' }}>
        <div className="alert alert-warning">
          שמע אין מחזור כזה בינתיים... באסה
        </div>
        {currentUser?.is_admin && (
          <div className="admin-controls">
            <a
              href="#"
              onClick={(e) => { e.preventDefault(); handleRunMigration(); }}
              className="admin-link"
            >
              הרץ מיגרציה
            </a>
          </div>
        )}
      </div>
    )
  }

  // Create a map of match_id to user bet
  const betsByMatchId = {}
  if (userBets?.bets) {
    userBets.bets.forEach(bet => {
      betsByMatchId[bet.match_id] = bet
    })
  }

  // Create a map of other users' bets by match_id
  const otherBetsByMatchId = {}
  if (otherUsersBets) {
    otherUsersBets.forEach(userBet => {
      userBet.bets.forEach(bet => {
        if (!otherBetsByMatchId[bet.match_id]) {
          otherBetsByMatchId[bet.match_id] = []
        }
        otherBetsByMatchId[bet.match_id].push({
          user: userBet.user,
          prediction: bet.prediction
        })
      })
    })
  }

  // Get other users for table headers (API already excludes current user)
  const otherUsers = otherUsersBets
    ? otherUsersBets.map(ub => ub.user)
    : []

  return (
    <div dir="rtl">
      {/* Page Header */}
      <div className="page-header">
        <h1 className="page-title">מחזור {fixture.number}</h1>
        {fixture.can_still_bet && fixture.seconds_left_to_bet > 0 && (
          <div className="time-left">
            <span className="time-left-icon">⏱️</span>
            {formatTimeLeft(fixture.seconds_left_to_bet)}
          </div>
        )}
      </div>

      {/* Mobile Card View */}
      <div className="matches-container">
        {matches.map(match => (
          <MatchCard
            key={match.id}
            match={match}
            bet={betsByMatchId[match.id]}
            onBetUpdate={handleBetUpdate}
            canBet={match.can_still_bet}
            otherBets={showOtherBets ? otherBetsByMatchId[match.id] : null}
          />
        ))}
      </div>

      {/* Desktop Table View */}
      <div className="matches-table-container">
        <table className="matches-table">
          <thead>
            <tr>
              <th>תאריך</th>
              <th>בית</th>
              <th></th>
              <th>חוץ</th>
              <th>תוצאה</th>
              <th>הימור</th>
              {showOtherBets && otherUsers.map(user => (
                <th key={user.id}>{user.name}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {matches.map(match => (
              <SingleMatch
                key={match.id}
                match={match}
                bet={betsByMatchId[match.id]}
                onBetUpdate={handleBetUpdate}
                canBet={match.can_still_bet}
                otherBets={showOtherBets ? otherBetsByMatchId[match.id] : null}
              />
            ))}
          </tbody>
        </table>
      </div>

      {/* Toggle Other Bets */}
      {!fixture.can_still_bet && otherUsersBets && (
        <div className="toggle-container">
          <input
            type="checkbox"
            id="showOtherBets"
            className="toggle-checkbox"
            checked={showOtherBets}
            onChange={(e) => setShowOtherBets(e.target.checked)}
          />
          <label htmlFor="showOtherBets" className="toggle-label">
            תראה את ההימורים של כולם
          </label>
        </div>
      )}

      {/* Fixture Navigation */}
      <div className="fixture-nav">
        <FixtureNavigation fixture={fixture} allFixtures={allFixtures} />
        
        <div className="fixture-dropdown">
          <button
            className="fixture-nav-btn"
            type="button"
            onClick={() => setDropdownOpen(!dropdownOpen)}
          >
            בחר מחזור <span style={{ marginRight: '4px' }}>▼</span>
          </button>
          {dropdownOpen && (
            <div className="fixture-dropdown-menu">
              {allFixtures.map(f => (
                <Link
                  key={f.number}
                  to={`/bets/${f.league_id}/${f.number}`}
                  className="fixture-dropdown-item"
                  onClick={() => setDropdownOpen(false)}
                >
                  מחזור {f.number}
                </Link>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Admin Controls */}
      {currentUser?.is_admin && (
        <div className="admin-controls">
          <button
            className="admin-btn"
            onClick={handleToggleOpen}
          >
            {fixture.is_open ? 'סגור מחזור' : 'פתח מחזור'}
          </button>
          <a
            href="#"
            onClick={(e) => { e.preventDefault(); handleRunMigration(); }}
            className="admin-link"
          >
            הרץ מיגרציה
          </a>
        </div>
      )}
    </div>
  )
}

function FixtureNavigation({ fixture, allFixtures }) {
  const currentIndex = allFixtures.findIndex(f => f.number === fixture.number)
  const prevFixture = currentIndex > 0 ? allFixtures[currentIndex - 1] : null
  const nextFixture = currentIndex < allFixtures.length - 1 ? allFixtures[currentIndex + 1] : null

  return (
    <>
      {prevFixture && (
        <Link
          to={`/bets/${prevFixture.league_id}/${prevFixture.number}`}
          className="fixture-nav-btn"
        >
          → מחזור קודם
        </Link>
      )}
      {nextFixture && (
        <Link
          to={`/bets/${nextFixture.league_id}/${nextFixture.number}`}
          className="fixture-nav-btn"
        >
          מחזור הבא ←
        </Link>
      )}
    </>
  )
}

function formatTimeLeft(seconds) {
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)

  if (hours > 0) {
    return `${hours} שעות ו-${minutes} דקות`
  }
  return `${minutes} דקות`
}
