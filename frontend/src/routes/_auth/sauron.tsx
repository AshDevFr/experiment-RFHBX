import { Container, Text, Title } from '@mantine/core';
import { createFileRoute } from '@tanstack/react-router';

export const Route = createFileRoute('/_auth/sauron')({
  component: SauronPage,
});

function SauronPage() {
  return (
    <Container>
      <Title order={2} mb="md">
        SAURON
      </Title>
      <Text c="dimmed" size="sm">
        Sauron panel coming in Phase 7.4.
      </Text>
    </Container>
  );
}
