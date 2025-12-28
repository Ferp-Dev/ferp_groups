import React, { useState, useEffect } from 'react';
import { MantineProvider } from '@mantine/core';
import { useNuiEvent } from './hooks/useNuiEvent';
import Home from './components/Home';
import Lobby from './components/Lobby';
import theme from './utils/theme';
import './index.css';

interface Member {
    source: number;
    name: string;
    isReady: boolean;
}

interface GroupData {
    id: string;
    ownerId: number;
    ownerName: string;
    members: Member[];
    state: string;
    statusText?: string;
}

const App: React.FC = () => {
    const [group, setGroup] = useState<GroupData | null>(null);
    const [myId, setMyId] = useState<number>(-1);

    useNuiEvent('updateGroup', (packet: { group: GroupData | null, myId: number }) => {
        setGroup(packet?.group || null);
        if (packet?.myId) setMyId(packet.myId);
    });

    useNuiEvent('activityStarted', (data: any) => {
    });// Maybe show a "Game Started" loading screen or just stay in lobby

    return (
        <MantineProvider theme={theme} withGlobalStyles withNormalizeCSS>
            <div className="App" style={{ height: '100vh', padding: '20px', backgroundColor: '#1A1B1E' }}>
                {group ? (
                    <Lobby group={group} myId={myId} />
                ) : (
                    <Home onJoin={() => { }} />
                )}
            </div>
        </MantineProvider>
    );
};

export default App;
