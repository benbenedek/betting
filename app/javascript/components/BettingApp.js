import React from 'react'
import { BrowserRouter, Routes, Route, Link } from 'react-router-dom'
import BetsList from './Bets/BetsList'
import ScoreTable from './Scores/ScoreTable'

export default function BettingApp({ current_user, csrf_token, league_id, number }) {
  return (
    <BrowserRouter>
      <nav className="navbar navbar-default">
        <div className="container">
          <div className="navbar-header">
            <Link to="/" className="navbar-brand">Betting App</Link>
          </div>
          <ul className="nav navbar-nav">
            <li><Link to="/bets">הימורים</Link></li>
            <li><Link to="/scores">טבלה</Link></li>
          </ul>
          <ul className="nav navbar-nav navbar-right">
            {current_user && (
              <li className="navbar-text">
                מחובר: {current_user.name}
              </li>
            )}
            <li>
              <a href="/classic/">גרסה קלאסית</a>
            </li>
          </ul>
        </div>
      </nav>

      <div className="container">
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
      </div>
    </BrowserRouter>
  )
}
