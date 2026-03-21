import { Container, Text, Title } from '@mantine/core';
import { createFileRoute } from '@tanstack/react-router';

export const Route = createFileRoute('/_auth/fellowship')({
  component: FellowshipPage,
});

function FellowshipPage() {
  return (
    <Container>
      <Title order={2} mb="md">
        FELLOWSHIP
      </Title>
      <Text c="dimmed" size="sm">
        Character roster coming in Phase 7.2.
      </Text>
    </Container>
  );
}
