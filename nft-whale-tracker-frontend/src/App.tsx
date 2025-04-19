import { useState } from 'react'
import './App.css'
import './styles/theme.css'
import MainLayout from './components/Layout/MainLayout'
import Dashboard from './pages/WhaleTrack'
import Opportunity from './pages/NftSnipe'
import Strategy from './pages/Strategy'
import Setting from './pages/Setting'
import TradingTrend from './pages/TradingTrend'

function App() {
  const [currentPage, setCurrentPage] = useState<string>('1')

  const renderContent = () => {
    switch (currentPage) {
      case '1':
        return <Dashboard />
      case '2':
        return <Opportunity />
      case '3':
        return <Strategy />
      case '4':
        return <Setting />
      case '5':
        return <TradingTrend />
      default:
        return <Dashboard />
    }
  }

  return (
    <MainLayout setCurrentPage={setCurrentPage}>
      {renderContent()}
    </MainLayout>
  )
}

export default App
