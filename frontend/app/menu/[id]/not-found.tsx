import Link from "next/link";

import { Button } from "@/components/ui/button";

export default function NotFound() {
  return (
    <main className="container mx-auto max-w-2xl px-4 py-8">
      <div className="mt-16 text-center">
        <h1 className="font-display text-4xl font-bold text-navy">
          Menu not found
        </h1>
        <p className="mt-3 text-muted-foreground">
          This menu does not exist or has been removed.
        </p>
        <Link href="/">
          <Button size="lg" className="mt-8">
            Upload a new menu
          </Button>
        </Link>
      </div>
    </main>
  );
}
