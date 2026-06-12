export function LoadingState() {
  return (
    <div className="rounded-lg border bg-card p-10 text-center shadow-card">
      <div className="mb-4 flex items-center justify-center gap-2">
        <span className="h-3 w-3 rounded-full bg-coral dot-bounce" />
        <span
          className="h-3 w-3 rounded-full bg-navy dot-bounce"
          style={{ animationDelay: "0.15s" }}
        />
        <span
          className="h-3 w-3 rounded-full bg-gold dot-bounce"
          style={{ animationDelay: "0.3s" }}
        />
      </div>
      <p className="font-display text-lg text-navy">Reading the menu</p>
      <p className="mt-1 text-sm text-muted-foreground">
        Extracting and translating dishes — about 10 seconds.
      </p>
    </div>
  );
}
