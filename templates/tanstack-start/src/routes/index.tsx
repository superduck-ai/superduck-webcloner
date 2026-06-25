import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/")({
  component: HomePage,
});

function HomePage() {
  return (
    <main className="flex min-h-screen items-center justify-center">
      <p className="text-muted-foreground">
        Clone target not yet built. Run{" "}
        <code className="font-mono text-foreground">/clone-website</code> to
        start.
      </p>
    </main>
  );
}
