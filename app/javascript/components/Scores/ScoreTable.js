import React, { useState, useEffect, useRef } from 'react'
import { useParams, Link } from 'react-router-dom'
import api from '../../lib/api'

// Medal/trophy icons for podium
const RANK_ICONS = {
  1: '🏆',
  2: '🥈',
  3: '🥉'
}

// Row colors for top positions
const RANK_COLORS = {
  1: 'linear-gradient(90deg, rgba(255,215,0,0.3) 0%, rgba(255,215,0,0.1) 100%)',
  2: 'linear-gradient(90deg, rgba(192,192,192,0.3) 0%, rgba(192,192,192,0.1) 100%)',
  3: 'linear-gradient(90deg, rgba(205,127,50,0.3) 0%, rgba(205,127,50,0.1) 100%)'
}

// CSS for responsive styles
const mobileStyles = `
  @media (max-width: 768px) {
    .podium-container {
      flex-direction: column !important;
      align-items: center !important;
      gap: 15px !important;
    }
    .podium-card {
      width: 100% !important;
      max-width: 200px !important;
    }
    .podium-bar {
      height: 80px !important;
      flex-direction: row !important;
      justify-content: space-around !important;
      border-radius: 8px !important;
    }
    .score-table-main th,
    .score-table-main td {
      padding: 6px 4px !important;
      font-size: 0.85em !important;
    }
    .hide-on-mobile {
      display: none !important;
    }
    .stat-boxes {
      gap: 10px !important;
    }
    .stat-box {
      min-width: 80px !important;
      padding: 8px 10px !important;
    }
    .mini-chart-container {
      overflow-x: auto;
    }
  }
`

export default function ScoreTable() {
  const params = useParams()
  const leagueId = params.leagueId || 10

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [data, setData] = useState(null)
  const [dropdownOpen, setDropdownOpen] = useState(false)
  const [expandedRow, setExpandedRow] = useState(null)
  const [sortBy, setSortBy] = useState('total')
  const [sortAsc, setSortAsc] = useState(false)
  const chartRef = useRef(null)
  const chartInstance = useRef(null)

  // Inject mobile styles
  useEffect(() => {
    const styleId = 'score-table-mobile-styles'
    if (!document.getElementById(styleId)) {
      const style = document.createElement('style')
      style.id = styleId
      style.textContent = mobileStyles
      document.head.appendChild(style)
    }
  }, [])

  useEffect(() => {
    const loadScores = async () => {
      try {
        setLoading(true)
        setError(null)
        const result = await api.getScores(leagueId)
        setData(result)
      } catch (err) {
        setError(err.message)
      } finally {
        setLoading(false)
      }
    }

    loadScores()
  }, [leagueId])

  useEffect(() => {
    if (!data?.graph_data || !chartRef.current) return

    const loadChart = async () => {
      if (!window.Chart) {
        await new Promise((resolve, reject) => {
          const script = document.createElement('script')
          script.src = 'https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js'
          script.onload = resolve
          script.onerror = reject
          document.head.appendChild(script)
        })
      }

      if (chartInstance.current) {
        chartInstance.current.destroy()
      }

      const ctx = chartRef.current.getContext('2d')
      chartInstance.current = new window.Chart(ctx, {
        type: 'line',
        data: data.graph_data,
        options: {
          responsive: true,
          maintainAspectRatio: true,
          interaction: {
            mode: 'index',
            intersect: false,
          },
          plugins: {
            legend: {
              position: 'top',
              labels: {
                boxWidth: 12,
                font: { size: 11 }
              }
            },
            title: {
              display: true,
              text: 'התקדמות לאורך העונה',
              font: { size: 16 }
            },
            tooltip: {
              callbacks: {
                label: function(context) {
                  return `${context.dataset.label}: ${context.parsed.y} נקודות`
                }
              }
            }
          },
          scales: {
            y: {
              beginAtZero: true,
              title: {
                display: true,
                text: 'נקודות מצטברות'
              }
            }
          }
        }
      })
    }

    loadChart()

    return () => {
      if (chartInstance.current) {
        chartInstance.current.destroy()
      }
    }
  }, [data])

  // Sort scores
  const getSortedScores = () => {
    if (!data?.scores) return []
    
    const sorted = [...data.scores].sort((a, b) => {
      let aVal, bVal
      
      if (sortBy === 'total') {
        aVal = a.total_success
        bVal = b.total_success
      } else if (sortBy === 'accuracy') {
        aVal = a.accuracy
        bVal = b.accuracy
      } else if (sortBy === 'user') {
        aVal = a.user
        bVal = b.user
        return sortAsc ? aVal.localeCompare(bVal) : bVal.localeCompare(aVal)
      } else {
        // Sort by specific fixture
        const aFixture = a.fixtures.find(f => f.fixture === sortBy)
        const bFixture = b.fixtures.find(f => f.fixture === sortBy)
        aVal = aFixture?.success || 0
        bVal = bFixture?.success || 0
      }
      
      return sortAsc ? aVal - bVal : bVal - aVal
    })
    
    return sorted
  }

  const handleSort = (column) => {
    if (sortBy === column) {
      setSortAsc(!sortAsc)
    } else {
      setSortBy(column)
      setSortAsc(false)
    }
  }

  const toggleRowExpand = (userName) => {
    setExpandedRow(expandedRow === userName ? null : userName)
  }

  if (loading) {
    return <div className="text-center" style={{ padding: '50px' }}><p>טוען...</p></div>
  }

  if (error) {
    return <div className="alert alert-danger">{error}</div>
  }

  if (!data) {
    return <div className="alert alert-warning">אין נתונים</div>
  }

  const sortedScores = getSortedScores()
  const top3 = data.scores.slice(0, 3)

  return (
    <div className="score-table" dir="rtl">
      {/* Header */}
      <div style={{ marginBottom: '20px' }}>
        <h1 style={{ fontSize: 'clamp(1.5rem, 5vw, 2rem)' }}>{data.league.name}</h1>
        <div className="dropdown" style={{ position: 'relative', display: 'inline-block' }}>
          לך לליגה{' '}
          <button
            className="btn btn-default dropdown-toggle"
            type="button"
            onClick={() => setDropdownOpen(!dropdownOpen)}
            style={{ minHeight: '44px' }}
          >
            בחר ליגה <span className="caret"></span>
          </button>
          {dropdownOpen && (
            <ul className="dropdown-menu" style={{ display: 'block' }}>
              {data.all_leagues.map(league => (
                <li key={league.id} style={{ minHeight: '44px', display: 'flex', alignItems: 'center' }}>
                  <Link 
                    to={`/scores/${league.id}`} 
                    onClick={() => setDropdownOpen(false)}
                    style={{ padding: '10px 15px', display: 'block', width: '100%' }}
                  >
                    {league.name}
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>

      {/* Podium for Top 3 */}
      {top3.length >= 3 && (
        <div 
          className="podium-container"
          style={{
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'flex-end',
            gap: '20px',
            marginBottom: '40px',
            padding: '20px',
            flexWrap: 'wrap'
          }}
        >
          {/* 2nd Place */}
          <PodiumCard user={top3[1]} rank={2} />
          {/* 1st Place */}
          <PodiumCard user={top3[0]} rank={1} />
          {/* 3rd Place */}
          <PodiumCard user={top3[2]} rank={3} />
        </div>
      )}

      {/* Main Table */}
      <div className="h-scroller" style={{ WebkitOverflowScrolling: 'touch' }}>
        <table className="table table-hover score-table-main" style={{ marginBottom: '30px' }}>
          <thead>
            <tr>
              <SortableHeader column="user" label="#" sortBy={sortBy} sortAsc={sortAsc} onSort={handleSort} />
              <th>שחקן</th>
              <SortableHeader column="accuracy" label="%" sortBy={sortBy} sortAsc={sortAsc} onSort={handleSort} />
              <th className="hide-on-mobile">פורמה</th>
              <th className="hide-on-mobile">מחזור מוצלח</th>
              {data.table_head.slice(1, -1).map((header, index) => (
                <SortableHeader 
                  key={index} 
                  column={header} 
                  label={header} 
                  sortBy={sortBy} 
                  sortAsc={sortAsc} 
                  onSort={handleSort}
                  className="hide-on-mobile"
                />
              ))}
              <SortableHeader column="total" label='סה"כ' sortBy={sortBy} sortAsc={sortAsc} onSort={handleSort} />
            </tr>
          </thead>
          <tbody>
            {sortedScores.map((row, rowIndex) => {
              const originalRank = data.scores.findIndex(s => s.user === row.user) + 1
              const isExpanded = expandedRow === row.user
              
              return (
                <React.Fragment key={row.user}>
                  <tr 
                    onClick={() => toggleRowExpand(row.user)}
                    style={{
                      background: RANK_COLORS[originalRank] || 'transparent',
                      cursor: 'pointer',
                      transition: 'all 0.2s ease'
                    }}
                    title="לחץ להרחבה"
                  >
                    <td style={{ fontWeight: 'bold', minWidth: '30px' }}>
                      {RANK_ICONS[originalRank] || originalRank}
                    </td>
                    <td style={{ fontWeight: originalRank <= 3 ? 'bold' : 'normal' }}>
                      {row.user}
                      <span style={{ opacity: 0.5, fontSize: '0.8em' }}>{isExpanded ? ' ▲' : ' ▼'}</span>
                    </td>
                    <td>
                      <AccuracyBadge accuracy={row.accuracy} />
                    </td>
                    <td className="hide-on-mobile">
                      <FormGuide form={row.form_guide} />
                    </td>
                    <td className="hide-on-mobile">
                      {row.best_fixture && (
                        <span 
                          className="label label-success"
                          title={`${row.best_fixture.success} נקודות במחזור ${row.best_fixture.number}`}
                        >
                          {row.best_fixture.number} ({row.best_fixture.success})
                        </span>
                      )}
                    </td>
                    {row.fixtures.slice(0, -1).map((fixture, colIndex) => (
                      <td 
                        key={colIndex}
                        className="hide-on-mobile"
                        style={{
                          backgroundColor: getScoreColor(fixture.success, fixture.games),
                          textAlign: 'center'
                        }}
                        title={`${fixture.success}/${fixture.games} משחקים`}
                      >
                        {fixture.success}
                      </td>
                    ))}
                    <td style={{ fontWeight: 'bold', fontSize: '1.1em' }}>
                      {row.total_success}
                    </td>
                  </tr>
                  
                  {/* Expanded Row Details */}
                  {isExpanded && (
                    <tr>
                      <td colSpan={data.table_head.length + 4} style={{ 
                        backgroundColor: '#f9f9f9', 
                        padding: '15px'
                      }}>
                        <ExpandedDetails row={row} tableHead={data.table_head} />
                      </td>
                    </tr>
                  )}
                </React.Fragment>
              )
            })}
          </tbody>
        </table>
      </div>

      {/* Chart */}
      <div style={{ 
        marginTop: '30px', 
        padding: '15px', 
        backgroundColor: '#fff', 
        borderRadius: '8px',
        overflowX: 'auto',
        WebkitOverflowScrolling: 'touch'
      }}>
        <canvas ref={chartRef} style={{ maxWidth: '100%', height: 'auto' }}></canvas>
      </div>
    </div>
  )
}

// Podium Card Component
function PodiumCard({ user, rank }) {
  const heights = { 1: 120, 2: 90, 3: 70 }
  const colors = { 1: '#FFD700', 2: '#C0C0C0', 3: '#CD7F32' }
  
  return (
    <div 
      className="podium-card"
      style={{
        textAlign: 'center',
        width: rank === 1 ? '130px' : '110px',
        flexShrink: 0
      }}
    >
      <div style={{ fontSize: rank === 1 ? '2.5em' : '1.8em', marginBottom: '8px' }}>
        {RANK_ICONS[rank]}
      </div>
      <div style={{
        fontWeight: 'bold',
        fontSize: rank === 1 ? '1.1em' : '1em',
        marginBottom: '8px',
        overflow: 'hidden',
        textOverflow: 'ellipsis',
        whiteSpace: 'nowrap'
      }}>
        {user.user}
      </div>
      <div 
        className="podium-bar"
        style={{
          height: `${heights[rank]}px`,
          backgroundColor: colors[rank],
          borderRadius: '8px 8px 0 0',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          color: rank === 1 ? '#333' : '#fff',
          fontWeight: 'bold',
          boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
        }}
      >
        <div style={{ fontSize: '1.3em' }}>{user.total_success}</div>
        <div style={{ fontSize: '0.7em', opacity: 0.8 }}>נקודות</div>
        <div style={{ fontSize: '0.8em', marginTop: '3px' }}>{user.accuracy}%</div>
      </div>
    </div>
  )
}

// Sortable Header Component
function SortableHeader({ column, label, sortBy, sortAsc, onSort, className }) {
  const isActive = sortBy === column
  
  return (
    <th 
      onClick={() => onSort(column)}
      className={className}
      style={{ 
        cursor: 'pointer',
        userSelect: 'none',
        backgroundColor: isActive ? '#e8e8e8' : 'transparent',
        minHeight: '44px',
        padding: '10px 8px'
      }}
      title="לחץ למיון"
    >
      {label}
      {isActive && (
        <span style={{ marginRight: '3px', fontSize: '0.8em' }}>
          {sortAsc ? '↑' : '↓'}
        </span>
      )}
    </th>
  )
}

// Accuracy Badge Component
function AccuracyBadge({ accuracy }) {
  let badgeClass = 'label-default'
  if (accuracy >= 60) badgeClass = 'label-success'
  else if (accuracy >= 45) badgeClass = 'label-info'
  else if (accuracy >= 30) badgeClass = 'label-warning'
  else badgeClass = 'label-danger'
  
  return (
    <span className={`label ${badgeClass}`} style={{ fontSize: '0.85em', padding: '4px 6px' }}>
      {accuracy}%
    </span>
  )
}

// Form Guide Component
function FormGuide({ form }) {
  if (!form || form.length === 0) return null
  
  return (
    <div style={{ display: 'flex', gap: '2px', justifyContent: 'center' }}>
      {form.map((result, index) => (
        <span
          key={index}
          style={{
            width: '18px',
            height: '18px',
            borderRadius: '50%',
            backgroundColor: result === 'W' ? '#5cb85c' : '#d9534f',
            color: 'white',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: '0.65em',
            fontWeight: 'bold'
          }}
          title={result === 'W' ? 'מחזור מוצלח' : 'מחזור חלש'}
        >
          {result === 'W' ? '✓' : '✗'}
        </span>
      ))}
    </div>
  )
}

// Get color based on score performance
function getScoreColor(success, games) {
  if (!games || games === 0) return 'transparent'
  const ratio = success / games
  
  if (ratio >= 0.7) return 'rgba(92, 184, 92, 0.3)'  // Green
  if (ratio >= 0.5) return 'rgba(91, 192, 222, 0.3)' // Blue
  if (ratio >= 0.3) return 'rgba(240, 173, 78, 0.3)' // Orange
  return 'rgba(217, 83, 79, 0.2)' // Red
}

// Expanded Details Component
function ExpandedDetails({ row, tableHead }) {
  const fixtureData = row.fixtures.slice(0, -1)
  
  // Calculate stats
  const bestFixture = fixtureData.reduce((best, curr) => 
    curr.success > (best?.success || 0) ? curr : best, null)
  const worstFixture = fixtureData.reduce((worst, curr) => 
    curr.success < (worst?.success || Infinity) ? curr : worst, null)
  
  const avgPerFixture = row.total_games > 0 
    ? (row.total_success / fixtureData.length).toFixed(1) 
    : 0

  return (
    <div dir="rtl">
      <h4 style={{ marginBottom: '15px', fontSize: 'clamp(1rem, 4vw, 1.25rem)' }}>
        📊 סטטיסטיקות - {row.user}
      </h4>
      
      <div 
        className="stat-boxes"
        style={{ 
          display: 'flex', 
          gap: '15px', 
          flexWrap: 'wrap', 
          marginBottom: '15px',
          justifyContent: 'flex-start'
        }}
      >
        <StatBox label="משחקים" value={row.total_games} />
        <StatBox label="נכונים" value={row.total_success} />
        <StatBox label="אחוז" value={`${row.accuracy}%`} />
        <StatBox label="ממוצע" value={avgPerFixture} />
        <StatBox 
          label="הכי טוב" 
          value={bestFixture ? `${bestFixture.fixture}` : '-'} 
          color="#5cb85c"
        />
        <StatBox 
          label="הכי חלש" 
          value={worstFixture ? `${worstFixture.fixture}` : '-'} 
          color="#d9534f"
        />
      </div>

      {/* Mini chart for this user */}
      <div className="mini-chart-container" style={{ marginTop: '10px' }}>
        <strong>ביצועים לפי מחזור:</strong>
        <div style={{ 
          display: 'flex', 
          gap: '4px', 
          marginTop: '10px', 
          alignItems: 'flex-end', 
          height: '50px',
          overflowX: 'auto',
          paddingBottom: '5px'
        }}>
          {fixtureData.map((fixture, index) => {
            const maxSuccess = Math.max(...fixtureData.map(f => f.success || 0), 1)
            const height = ((fixture.success || 0) / maxSuccess) * 40 + 10
            
            return (
              <div
                key={index}
                style={{
                  minWidth: '22px',
                  width: '22px',
                  height: `${height}px`,
                  backgroundColor: fixture.success >= (fixture.games / 2) ? '#5cb85c' : '#d9534f',
                  borderRadius: '3px 3px 0 0',
                  display: 'flex',
                  alignItems: 'flex-end',
                  justifyContent: 'center',
                  color: 'white',
                  fontSize: '0.65em',
                  paddingBottom: '2px',
                  flexShrink: 0
                }}
                title={`מחזור ${fixture.fixture}: ${fixture.success}/${fixture.games}`}
              >
                {fixture.success}
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}

// Stat Box Component
function StatBox({ label, value, color }) {
  return (
    <div 
      className="stat-box"
      style={{
        textAlign: 'center',
        padding: '8px 12px',
        backgroundColor: '#fff',
        borderRadius: '8px',
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
        minWidth: '70px',
        flex: '0 0 auto'
      }}
    >
      <div style={{ fontSize: '0.7em', color: '#666', marginBottom: '3px' }}>{label}</div>
      <div style={{ fontSize: '1em', fontWeight: 'bold', color: color || '#333' }}>{value}</div>
    </div>
  )
}
