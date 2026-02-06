import React, { useState, useEffect, useCallback } from 'react'
import { useParams, Link } from 'react-router-dom'
import api from '../../lib/api'
import SingleMatch from './SingleMatch'

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
    return <div className="text-center"><p>טוען...</p></div>
  }

  if (error) {
    return <div className="alert alert-danger">{error}</div>
  }

  if (!fixture) {
    return (
      <div className="fixture" dir="rtl">
        <div className="alert alert-warning">
          שמע אין מחזור כזה בינתיים... באסה
        </div>
        {currentUser?.is_admin && (
          <div>
            <a
              href="#"
              onClick={(e) => { e.preventDefault(); handleRunMigration(); }}
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
    <div className="fixture" dir="rtl">
      <h1>מחזור כדורגל {fixture.number}</h1>

      {fixture.can_still_bet && fixture.seconds_left_to_bet > 0 && (
        <p className="text-muted">
          זמן שנותר להימור: {formatTimeLeft(fixture.seconds_left_to_bet)}
        </p>
      )}

      <div className="h-scroller">
        <table className="table">
          <thead>
            <tr>
              <th className="hidden-sm hidden-xs">תאריך</th>
              <th>בית</th>
              <th></th>
              <th>חוץ</th>
              <th>תוצאה</th>
              <th>הימור</th>
              {showOtherBets && otherUsers.map(user => (
                <th key={user.id}>{user.name}</th>
              ))}
              <th></th>
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

      {!fixture.can_still_bet && otherUsersBets && (
        <div className="checkbox">
          <label>
            <input
              type="checkbox"
              checked={showOtherBets}
              onChange={(e) => setShowOtherBets(e.target.checked)}
            />
            תראה את ההימורים של כולם
          </label>
        </div>
      )}

      <br />

      <div className="row">
        <div className="col-md-2">
          <FixtureNavigation fixture={fixture} allFixtures={allFixtures} />
        </div>
        <div className="dropdown col-md-2" style={{ position: 'relative' }}>
          לך למחזור{' '}
          <button
            className="btn btn-default dropdown-toggle"
            type="button"
            onClick={() => setDropdownOpen(!dropdownOpen)}
          >
            בחר מחזור <span className="caret"></span>
          </button>
          {dropdownOpen && (
            <ul
              className="dropdown-menu"
              style={{ display: 'block' }}
            >
              {allFixtures.map(f => (
                <li key={f.number}>
                  <Link
                    to={`/bets/${f.league_id}/${f.number}`}
                    onClick={() => setDropdownOpen(false)}
                  >
                    מחזור {f.number}
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>

      {currentUser?.is_admin && (
        <div className="admin-controls" style={{ marginTop: '20px' }}>
          <button
            className="btn btn-warning"
            onClick={handleToggleOpen}
          >
            {fixture.is_open ? 'סגור מחזור' : 'פתח מחזור'}
          </button>
          <br />
          <a
            href="#"
            onClick={(e) => { e.preventDefault(); handleRunMigration(); }}
            style={{ marginTop: '10px', display: 'inline-block' }}
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
          className="btn btn-default btn-sm"
        >
          → מחזור קודם
        </Link>
      )}
      {' '}
      {nextFixture && (
        <Link
          to={`/bets/${nextFixture.league_id}/${nextFixture.number}`}
          className="btn btn-default btn-sm"
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
