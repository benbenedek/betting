// Entry point for React app
// This only mounts React on pages that opt-in via the react-root element
import React from 'react'
import { createRoot } from 'react-dom/client'
import BettingApp from './components/BettingApp'

document.addEventListener('DOMContentLoaded', () => {
  // Only mount if the React container exists (opt-in for React pages)
  const reactRoot = document.getElementById('react-root')
  if (reactRoot) {
    const root = createRoot(reactRoot)
    const props = JSON.parse(reactRoot.dataset.props || '{}')
    root.render(<BettingApp {...props} />)
  }
})
