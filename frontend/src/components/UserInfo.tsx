import { Avatar, Group, Menu, Text, UnstyledButton } from '@mantine/core';
import { useAuth } from '../auth/AuthContext';

/**
 * Displays the authenticated user's name or email in the header.
 * Shows a login prompt when unauthenticated.
 */
export function UserInfo() {
  const { user, isAuthenticated, isLoading, login, logout } = useAuth();

  if (isLoading) {
    return (
      <Text size="sm" c="dimmed">
        …
      </Text>
    );
  }

  if (!isAuthenticated || !user) {
    return (
      <UnstyledButton onClick={() => login()} style={{ fontSize: 'var(--mantine-font-size-sm)' }}>
        Sign in
      </UnstyledButton>
    );
  }

  // Prefer name from profile; fall back to email or subject claim.
  const profile = user.profile;
  const displayName = profile.name ?? profile.email ?? profile.sub ?? 'User';
  const initials = displayName
    .split(' ')
    .map((part: string) => part[0])
    .slice(0, 2)
    .join('')
    .toUpperCase();

  return (
    <Menu shadow="md" width={160}>
      <Menu.Target>
        <UnstyledButton>
          <Group gap="xs">
            <Avatar size="sm" radius="xl" color="retro">
              {initials}
            </Avatar>
            <Text size="sm" visibleFrom="sm">
              {displayName}
            </Text>
          </Group>
        </UnstyledButton>
      </Menu.Target>
      <Menu.Dropdown>
        <Menu.Label>{profile.email ?? ''}</Menu.Label>
        <Menu.Divider />
        <Menu.Item onClick={() => logout()} color="red">
          Sign out
        </Menu.Item>
      </Menu.Dropdown>
    </Menu>
  );
}
