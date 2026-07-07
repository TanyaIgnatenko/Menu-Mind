import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy — MenuMind",
  description: "How MenuMind handles the data you provide.",
};

export default function PrivacyPage() {
  return (
    <main className="mx-auto min-h-screen max-w-2xl bg-canvas px-5 py-10 md:py-14">
      <h1 className="font-display text-3xl font-extrabold tracking-tight text-ink">
        Privacy Policy
      </h1>
      <p className="mt-1 text-sm text-muted-2">Last updated: 7 July 2026</p>

      <div className="mt-6 space-y-6 text-[15px] leading-relaxed text-body">
        <p>
          MenuMind (&ldquo;we&rdquo;, &ldquo;the app&rdquo;) lets you photograph a
          restaurant menu and get every dish translated, each with an AI-generated
          image. This policy explains what data we handle. MenuMind has no account
          or login.
        </p>

        <section className="space-y-2">
          <h2 className="font-display text-lg font-bold text-ink">What we collect</h2>
          <ul className="list-disc space-y-1 pl-5">
            <li>
              <strong className="text-ink">Menu photos you upload.</strong> When you
              scan a menu, the photo is sent to our servers to extract and translate
              the dishes.
            </li>
            <li>
              <strong className="text-ink">Generated content.</strong> The translated
              menu text and AI-generated dish images produced from your photo.
            </li>
            <li>
              <strong className="text-ink">Technical data.</strong> Your IP address,
              used only to rate-limit uploads and prevent abuse, and basic anonymous
              usage analytics (which screens are used).
            </li>
          </ul>
          <p>
            We do <strong className="text-ink">not</strong> collect your name, email,
            contacts, precise location, or any account information.
          </p>
        </section>

        <section className="space-y-2">
          <h2 className="font-display text-lg font-bold text-ink">How we use it</h2>
          <ul className="list-disc space-y-1 pl-5">
            <li>To extract, translate, and visualize the dishes on the menu you scanned.</li>
            <li>To cache results so re-scanning the same menu is instant.</li>
            <li>To keep the service reliable (rate limiting) and improve it (aggregate analytics).</li>
          </ul>
        </section>

        <section className="space-y-2">
          <h2 className="font-display text-lg font-bold text-ink">
            Third parties we share data with
          </h2>
          <p>
            To provide the service, your menu photo and/or the extracted text are
            processed by:
          </p>
          <ul className="list-disc space-y-1 pl-5">
            <li><strong className="text-ink">Google Gemini</strong> — menu reading and translation.</li>
            <li><strong className="text-ink">Fal.ai / Flux</strong> — dish image generation.</li>
            <li><strong className="text-ink">PostHog</strong> (EU) — anonymous usage analytics.</li>
            <li>
              Hosting infrastructure — <strong className="text-ink">Railway</strong>,{" "}
              <strong className="text-ink">Amazon S3</strong>, and{" "}
              <strong className="text-ink">Vercel</strong>.
            </li>
          </ul>
          <p>We do not sell your data or use it for advertising.</p>
        </section>

        <section className="space-y-2">
          <h2 className="font-display text-lg font-bold text-ink">Retention</h2>
          <p>
            Your uploaded photo is processed to produce the translated menu and is not
            used for any other purpose. The resulting menu text and generated dish
            images are cached to speed up future scans. You can request deletion of
            data associated with your uploads (see Contact).
          </p>
        </section>

        <section className="space-y-2">
          <h2 className="font-display text-lg font-bold text-ink">Children</h2>
          <p>MenuMind is not directed at children under 13.</p>
        </section>

        <section className="space-y-2">
          <h2 className="font-display text-lg font-bold text-ink">Your rights &amp; contact</h2>
          <p>
            You may request access to, or deletion of, data associated with your
            uploads by emailing{" "}
            <a
              href="mailto:tanigna.work@gmail.com"
              className="font-semibold text-primary underline-offset-4 hover:underline"
            >
              tanigna.work@gmail.com
            </a>
            .
          </p>
        </section>
      </div>
    </main>
  );
}
