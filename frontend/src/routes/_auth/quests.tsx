import { Container, Text, Title } from '@mantine/core';
import { createFileRoute } from '@tanstack/react-router';

export const Route = createFileRoute('/_auth/quests')({
  component: QuestsPage,
});

function QuestsPage() {
  return (
    <Container>
      <Title order={2} mb="md">
        QUESTS
      </Title>
      <Text c="dimmed" size="sm">
        Quest dashboard coming in Phase 7.3.
      </Text>
    </Container>
  );
}
