import React from 'react'
import { BrowserRouter, Routes, Route, Link, useLocation } from 'react-router-dom'
import BetsList from './Bets/BetsList'
import ScoreTable from './Scores/ScoreTable'
import '../styles/app.css'

// Loading Spinner Component
export function LoadingSpinner({ text = 'טוען...' }) {
  return (
    <div className="loading-container">
      <div className="spinner"></div>
      <span className="loading-text">{text}</span>
    </div>
  )
}

// Bottom Navigation Component (Mobile)
function BottomNav() {
  const location = useLocation()
  const path = location.pathname

  const isActive = (route) => {
    if (route === '/bets') {
      return path === '/' || path.startsWith('/bets')
    }
    return path.startsWith(route)
  }

  return (
    <nav className="bottom-nav">
      <Link to="/bets" className={`bottom-nav-item ${isActive('/bets') ? 'active' : ''}`}>
        <span className="bottom-nav-icon">⚽</span>
        <span className="bottom-nav-label">הימורים</span>
      </Link>
      <Link to="/scores" className={`bottom-nav-item ${isActive('/scores') ? 'active' : ''}`}>
        <span className="bottom-nav-icon">🏆</span>
        <span className="bottom-nav-label">טבלה</span>
      </Link>
      <a href="/classic/" className="bottom-nav-item">
        <span className="bottom-nav-icon">📋</span>
        <span className="bottom-nav-label">קלאסי</span>
      </a>
    </nav>
  )
}

// Top Navigation Component (Desktop)
function TopNav({ currentUser }) {
  const location = useLocation()
  const path = location.pathname

  const isActive = (route) => {
    if (route === '/bets') {
      return path === '/' || path.startsWith('/bets')
    }
    return path.startsWith(route)
  }

  return (
    <nav className="top-nav">
      <div className="top-nav-content">
        <Link to="/" className="top-nav-brand">⚽ Betting App</Link>
        <ul className="top-nav-links">
          <li>
            <Link to="/bets" className={`top-nav-link ${isActive('/bets') ? 'active' : ''}`}>
              הימורים
            </Link>
          </li>
          <li>
            <Link to="/scores" className={`top-nav-link ${isActive('/scores') ? 'active' : ''}`}>
              טבלה
            </Link>
          </li>
          <li>
            <a href="/classic/" className="top-nav-link">
              גרסה קלאסית
            </a>
          </li>
        </ul>
        {currentUser && (
          <span className="top-nav-user">
            👤 {currentUser.name}
          </span>
        )}
      </div>
    </nav>
  )
}

export default function BettingApp({ current_user, csrf_token, league_id, number }) {
  return (
    <BrowserRouter>
      <div className="betting-app" dir="rtl">
        <TopNav currentUser={current_user} />

        <main>
          <Routes>
            <Route
              path="/"
              element={
                <BetsList
                  leagueId={league_id}
                  fixtureNumber={number}
                  csrfToken={csrf_token}
                />
              }
            />
            <Route
              path="/bets"
              element={<BetsList csrfToken={csrf_token} />}
            />
            <Route
              path="/bets/:leagueId/:fixtureNumber"
              element={<BetsList csrfToken={csrf_token} />}
            />
            <Route
              path="/scores"
              element={<ScoreTable />}
            />
            <Route
              path="/scores/:leagueId"
              element={<ScoreTable />}
            />
          </Routes>
        </main>

        <BottomNav />
      </div>
    </BrowserRouter>
  )
}
