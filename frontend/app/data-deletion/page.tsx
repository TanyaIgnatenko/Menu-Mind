import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Request data deletion — MenuMind",
  description: "How to request deletion of data associated with your MenuMind uploads.",
};

export default function DataDeletionPage() {
  return (
    <main className="mx-auto min-h-screen max-w-2xl bg-canvas px-5 py-10 md:py-14">
      <h1 className="font-display text-3xl font-extrabold tracking-tight text-ink">
        Request data deletion
      </h1>
      <p className="mt-1 text-sm text-muted-2">Last updated: 9 July 2026</p>

      <div className="mt-6 space-y-6 text-[15px] leading-relaxed text-body">
        <p>
          This page explains how to request deletion of data associated with your
          use of <strong className="text-ink">MenuMind</strong> (the app and web
          app). MenuMind has no account or login, so we hold no name, email, or
          profile for you unless you contact us.
        </p>

        <section className="space-y-2">
          <h2 className="font-display text-lg font-bold text-ink">
            How to request deletion
          </h2>
          <ol className="list-decimal space-y-2 pl-5">
            <li>
              Email{" "}
              <a
                href="mailto:tanigna.work@gmail.com?subject=MenuMind%20data%20deletion"
                className="font-semibold text-primary underline-offset-4 hover:underline"
              >
                tanigna.work@gmail.com
              </a>{" "}
              with the subject <strong className="text-ink">“MenuMind data deletion”</strong>.
            </li>
            <li>
              If your request is about a specific scan, include the menu link you
              shared (or the approximate date/time of the scan) so we can locate it.
              This is optional — since there is no account, identifying details are
              limited.
            </li>
            <li>
              We will delete the associated data and confirm by reply, normally
              within <strong className="text-ink">30 days</strong>.
            </li>
          </ol>
        </section>

        <section className="space-y-2">
          <h2 className="font-display text-lg font-bold text-ink">What we delete</h2>
          <ul className="list-disc space-y-1 pl-5">
            <li>
              <strong className="text-ink">Uploaded menu photos.</strong> Any menu
              photo you uploaded. (These are also{" "}
              <strong className="text-ink">automatically deleted within 30 days</strong>{" "}
              regardless of any request.)
            </li>
            <li>
              <strong className="text-ink">Extracted menu data.</strong> The
              translated menu text and AI-generated dish images produced from your
              uploads.
            </li>
            <li>
              <strong className="text-ink">Anonymous analytics.</strong> Usage events
              tied to your app install (e.g. scans performed). If you know your
              in-app install id you can include it; otherwise we remove events on
              request.
            </li>
          </ul>
        </section>

        <section className="space-y-2">
          <h2 className="font-display text-lg font-bold text-ink">
            What we keep, and retention
          </h2>
          <p>
            We do not keep any data tied to your real-world identity — MenuMind
            stores no name, email, or account. Uploaded menu photos are retained for
            at most <strong className="text-ink">30 days</strong> and then deleted
            automatically. The only email we hold is the one you send us to make a
            request, used solely to handle that request.
          </p>
        </section>

        <section className="space-y-2">
          <h2 className="font-display text-lg font-bold text-ink">More detail</h2>
          <p>
            See our{" "}
            <a
              href="/privacy"
              className="font-semibold text-primary underline-offset-4 hover:underline"
            >
              Privacy Policy
            </a>{" "}
            for the full description of what data MenuMind handles.
          </p>
        </section>
      </div>
    </main>
  );
}
