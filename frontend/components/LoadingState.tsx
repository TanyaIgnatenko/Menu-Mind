import { Card } from "@/components/ui/card";

export function LoadingState() {
  return (
    <Card className="p-8 text-center">
      <div className="flex items-center justify-center gap-3">
        <div className="h-4 w-4 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        <p className="text-muted-foreground">Extracting menu, this takes about 10 seconds...</p>
      </div>
    </Card>
  );
}
