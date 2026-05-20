import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Impressum – Numeris",
};

export default function ImpressumPage() {
  return (
    <div className="min-h-screen bg-white">
      <div className="max-w-2xl mx-auto px-6 py-12">
        <Link href="/dashboard" className="text-sm text-gray-400 hover:text-gray-700 mb-8 inline-block">
          ← Zurück zum Dashboard
        </Link>

        <h1 className="text-2xl font-bold text-gray-900 mb-8">Impressum</h1>

        <section className="space-y-6 text-gray-700 text-sm leading-relaxed">
          <div>
            <h2 className="font-semibold text-gray-900 mb-1">Angaben gemäß § 5 TMG</h2>
            {/* TODO: Replace with real name and address before going live */}
            <p>
              [Jakob Neumann]<br />
              [Eulerstraße 12]<br />
              [13357 Berlin]<br />
              Deutschland
            </p>
          </div>

          <div>
            <h2 className="font-semibold text-gray-900 mb-1">Kontakt</h2>
            <p>
              E-Mail:{" "}
              {/* TODO: Replace with contact email */}
              <a href="mailto:[jakob.neumann@schule.berlin.de]" className="underline hover:text-gray-900">
                [jakob.neumann@schule.berlin.de]
              </a>
            </p>
          </div>

          <div>
            <h2 className="font-semibold text-gray-900 mb-1">Verantwortlich für den Inhalt (§ 18 Abs. 2 MStV)</h2>
            <p>
              [Jakob Neumann]<br />
              [Eulerstraße 12]<br />
              [13357 Berlin]
            </p>
          </div>

          <div>
            <h2 className="font-semibold text-gray-900 mb-1">Haftungsausschluss</h2>
            <p>
              Die Inhalte dieser Seiten wurden mit größter Sorgfalt erstellt.
              Für die Richtigkeit, Vollständigkeit und Aktualität der Inhalte
              kann jedoch keine Gewähr übernommen werden.
            </p>
          </div>
        </section>

        <p className="mt-12 text-xs text-gray-400">
          Stand: Mai 2026
        </p>
      </div>
    </div>
  );
}
