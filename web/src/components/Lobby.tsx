import { Button, Paper, Title, Text, Stack, Card, Group, Badge, ActionIcon, ScrollArea, Avatar, Alert, Loader, Center } from '@mantine/core';
import { IconLogout, IconPlayerPlay, IconTrash, IconCheck, IconX, IconInfoCircle } from '@tabler/icons-react';
import { fetchNui } from '../utils/fetchNui';
import { isEnvBrowser } from '../utils/misc';

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
    job?: string;
}

interface LobbyProps {
    group: GroupData;
    myId: number;
}

const Lobby: React.FC<LobbyProps> = ({ group, myId }) => {
    // Check ownership
    const isOwner = group.ownerId === myId;

    const handleLeave = () => {
        fetchNui('leaveGroup');
    };
    const handleToggleReady = () => {
        fetchNui('toggleReady');
    };

    const handleStart = () => {
        fetchNui('startGame');
    };
    const handleCancel = () => {
        fetchNui('cancelActivity');
    };
    const handleKick = (targetSource: number) => {
        fetchNui('kickMember', { targetSource });
    };

    // Calculate if all ready
    const allReady = group.members.every(m => m.isReady);
    const amIReady = group.members.find(m => m.source === myId)?.isReady ?? false;

    return (
        <Paper p="md" radius={0} style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'transparent' }}>
            <Paper p="md" radius="lg" mb="md" style={{ backgroundColor: '#25262b' }}>
                <Group position="apart">
                    <Stack spacing={4}>
                        <Text size="xs" color="dimmed" transform="uppercase" weight={700}>Current Group</Text>
                        <Title order={3} weight={400}>{group.ownerName}'s Team</Title>
                    </Stack>
                    <Stack spacing={4} align="flex-end">
                        <Text size="xs" color="dimmed" transform="uppercase" weight={700}>Group ID</Text>
                        <Badge size="lg" radius="sm" variant="filled" color="dark">{group.id}</Badge>
                    </Stack>
                </Group>
            </Paper>

            {group.state === 'waiting' && (
                <Alert icon={<Loader size={16} variant="dots" />} title="Searching for Activity" color="yellow" radius="md" mb="md" variant="filled" styles={{ title: { color: 'black' }, message: { color: 'black' }, icon: { color: 'black' } }}>
                    Your group is currently in the queue for a job. Please wait.
                </Alert>
            )}

            {group.state === 'started' && (
                <Alert icon={<IconInfoCircle size={16} />} title="Job Active" color="blue" radius="md" mb="md" variant="filled" styles={{ title: { color: 'white' }, message: { color: 'white' }, icon: { color: 'white' } }}>
                    {group.statusText || ("In Progress: " + (group.job || "Unknown"))}
                </Alert>
            )}

            <Text size="sm" color="dimmed" mb="xs" ml="xs">Members ({group.members.length}/6)</Text>

            <ScrollArea style={{ flex: 1 }} offsetScrollbars>
                <Stack spacing="sm">
                    {group.members.map((member) => (
                        <Paper key={member.source} p="sm" radius="md" style={{ backgroundColor: '#2C2E33' }}>
                            <Group position="apart">
                                <Group spacing="md">
                                    <Avatar radius="xl" color="blue" variant="light">{member.name.charAt(0).toUpperCase()}</Avatar>
                                    <Stack spacing={0}>
                                        <Group spacing="xs">
                                            <Text weight={500} color="white">{member.name}</Text>
                                            {member.source === group.ownerId && <Badge size="xs" color="yellow" variant="dot">Owner</Badge>}
                                        </Group>
                                        <Text size="xs" color={member.isReady ? "green" : "dimmed"}>
                                            {member.isReady ? "Ready" : "Waiting..."}
                                        </Text>
                                    </Stack>
                                </Group>
                                <Group>
                                    {isOwner && member.source !== myId && (
                                        <ActionIcon
                                            color="red"
                                            variant="subtle"
                                            onClick={() => handleKick(member.source)}
                                            title="Kick Member"
                                        >
                                            <IconTrash size={18} />
                                        </ActionIcon>
                                    )}
                                </Group>
                            </Group>
                        </Paper>
                    ))}
                </Stack>
            </ScrollArea>

            <Paper p="md" radius="lg" mt="md" style={{ backgroundColor: '#25262b' }}>
                <Group grow spacing="md">
                    <Button
                        size="md"
                        variant="light"
                        color="red"
                        onClick={handleLeave}
                    >
                        Leave
                    </Button>

                    <Button
                        size="md"
                        variant={group.state === 'waiting' ? (isOwner ? "outline" : "subtle") : (amIReady || (isOwner && allReady) ? "filled" : "light")}
                        color={(group.state === 'waiting' || group.state === 'started') ? (isOwner ? "red" : "gray") : (isOwner && allReady ? "green" : (amIReady ? "blue" : "gray"))}
                        onClick={(group.state === 'waiting' || group.state === 'started') ? (isOwner ? handleCancel : undefined) : ((isOwner && allReady) ? handleStart : handleToggleReady)}
                        leftIcon={(group.state === 'waiting' || group.state === 'started') ? (isOwner ? <IconX size={20} /> : undefined) : ((isOwner && allReady) ? <IconPlayerPlay size={20} /> : (amIReady ? <IconCheck size={20} /> : undefined))}
                        disabled={(group.state === 'waiting' || group.state === 'started') && !isOwner}
                    >
                        {(group.state === 'waiting' || group.state === 'started') ? (isOwner ? "Cancel Activity" : "Activity in Progress...") : ((isOwner && allReady) ? "Start Activity" : (amIReady ? "Ready" : "Set Ready"))}
                    </Button>
                </Group>
            </Paper>
        </Paper>
    );
};

export default Lobby;
