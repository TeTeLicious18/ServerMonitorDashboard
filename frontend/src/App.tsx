import { useState, useEffect } from 'react';
import Dashboard from './components/Dashboard';
import Sidebar from './components/Sidebar';
import { Agent } from './types';

function App() {
  const [agents, setAgents] = useState<Agent[]>([]);
  const [selectedAgent, setSelectedAgent] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchAgents = async () => {
      try {
        setIsLoading(true);
        const response = await fetch('/api/agents');
        if (!response.ok) throw new Error('Failed to fetch agents');
        const data = await response.json();
        setAgents(data);
        if (data.length > 0 && !selectedAgent) {
          setSelectedAgent(data[0].agent_id);
        }
      } catch (error) {
        console.error('Error fetching agents:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchAgents();
    const interval = setInterval(fetchAgents, 30000); // Update every 30 seconds

    return () => clearInterval(interval);
  }, [selectedAgent]);

  return (
    <div className="flex h-screen bg-gray-900">
      <Sidebar 
        agents={agents} 
        selectedAgent={selectedAgent} 
        onSelectAgent={setSelectedAgent}
        isLoading={isLoading}
      />
      <main className="flex-1 overflow-y-auto">
        <Dashboard 
          agents={agents} 
          selectedAgent={selectedAgent}
          isLoading={isLoading}
        />
      </main>
    </div>
  );
}

export default App;
