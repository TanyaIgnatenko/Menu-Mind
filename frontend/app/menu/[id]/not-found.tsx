import Link from "next/link";

import { Button } from "@/components/ui/button";

export default function NotFound() {
  return (
    <main className="container mx-auto max-w-2xl p-4 py-8">
      <div className="mt-16 text-center">
        <h1 className="text-3xl font-bold">Menu not found</h1>
        <p className="mt-2 text-muted-foreground">
          This menu does not exist or has been removed.
        </p>
        <Link href="/">
          <Button className="mt-6">Upload a new menu</Button>
        </Link>
      </div>
    </main>
  );
}