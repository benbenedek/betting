// API helper for making requests to Rails backend
const API_BASE = '/api/v1'

async function request(url, options = {}) {
  const { headers: customHeaders, ...restOptions } = options
  const response = await fetch(`${API_BASE}${url}`, {
    credentials: 'same-origin',
    ...restOptions,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...customHeaders,
    },
  })

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Request failed' }))
    throw new Error(error.error || 'Request failed')
  }

  return response.json()
}

export const api = {
  // Get current fixture with matches and user bets
  getCurrentFixture: () => request('/fixtures/current'),

  // Get specific fixture by league and number
  getFixture: (leagueId, number) => request(`/fixtures/${leagueId}/${number}`),

  // Update a bet prediction
  updateBet: (betId, prediction, csrfToken) =>
    request(`/bets/${betId}`, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
      },
      body: JSON.stringify({ prediction }),
    }),

  // Get all users' bets for a fixture (only works after betting closes)
  getAllBets: (fixtureId) => request(`/fixtures/${fixtureId}/all_bets`),

  // Admin: toggle fixture open/close
  toggleFixtureOpen: (fixtureId, isOpen, csrfToken) =>
    request(`/fixtures/${fixtureId}/toggle_open`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
      },
      body: JSON.stringify({ is_open: isOpen }),
    }),

  // Admin: run migration to fetch scores
  runMigration: (leagueId, number, csrfToken) =>
    request(`/fixtures/${leagueId}/${number}/run_migration`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
      },
    }),

  // Get current user info
  getCurrentUser: () => request('/users/current'),

  // Get scores/leaderboard for a league
  getScores: (leagueId = 10) => request(`/scores/${leagueId}`),
}

export default api
