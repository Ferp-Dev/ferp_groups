import React, { useState } from 'react';
import { Button, TextInput, Paper, Title, Stack, Group, Text, Divider } from '@mantine/core';
import { fetchNui } from '../utils/fetchNui';
import { isEnvBrowser } from '../utils/misc';

interface HomeProps {
    onJoin: () => void;
}

const Home: React.FC<HomeProps> = ({ onJoin }) => {
    const [joinId, setJoinId] = useState('');
    const [loading, setLoading] = useState(false);

    const handleCreate = async () => {
        setLoading(true);
        try {
            await fetchNui('createGroup');
            setLoading(false);
        } catch (e) {
            console.error(e);
            setLoading(false);
        }
    };

    const handleJoin = async () => {
        if (!joinId) return;
        setLoading(true);
        try {
            await fetchNui('joinGroup', { filterName: joinId });
            setLoading(false);
        } catch (e) {
            console.error(e);
            setLoading(false);
        }
    };

    return (
        <Paper p="xl" radius="md" style={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'center', background: 'transparent' }}>
            <Stack spacing="xl" align="center" style={{ width: '100%', maxWidth: 400, margin: '0 auto' }}>
                <Title order={1} align="center" style={{ fontWeight: 300, letterSpacing: 1 }}>Groups</Title>
                <Text color="dimmed" size="sm" align="center" mt={-15}>Create or join a team to start an activity.</Text>

                <Paper withBorder p="lg" radius="lg" style={{ width: '100%', backgroundColor: '#25262b' }}>
                    <Stack spacing="md">
                        <Button
                            fullWidth
                            size="lg"
                            radius="md"
                            variant="gradient"
                            gradient={{ from: 'indigo', to: 'cyan' }}
                            onClick={handleCreate}
                            loading={loading}
                        >
                            Create New Group
                        </Button>

                        <Divider label="or join existing" labelPosition="center" my="sm" />

                        <Group spacing="xs" grow>
                            <TextInput
                                placeholder="Search Group ID..."
                                radius="md"
                                size="md"
                                value={joinId}
                                onChange={(e) => setJoinId(e.currentTarget.value)}
                            />
                            <Button
                                size="md"
                                radius="md"
                                variant="light"
                                color="cyan"
                                onClick={() => {
                                    if (!joinId) return;
                                    setLoading(true);
                                    fetchNui('joinGroup', { filterName: joinId })
                                        .finally(() => setLoading(false));
                                }}
                                loading={loading}
                                disabled={!joinId}
                                style={{ flex: 0 }}
                            >
                                Join
                            </Button>
                        </Group>
                    </Stack>
                </Paper>
            </Stack>
        </Paper>
    );
};

export default Home;
