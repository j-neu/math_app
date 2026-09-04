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
            <h2 className="font-semibold text-gray-900 mb-1">Angaben gemäß § 5 DDG</h2>
            {/* TODO: Real name and address eintragen, bevor diese Seite veröffentlicht wird. */}
            <p>
              [Name]<br />
              [Straße und Hausnummer]<br />
              [Postleitzahl und Ort]<br />
              Deutschland
            </p>
          </div>

          <div>
            <h2 className="font-semibold text-gray-900 mb-1">Kontakt</h2>
            {/* TODO: Echte Kontaktadresse eintragen, bevor diese Seite veröffentlicht wird. */}
            <p>E-Mail: [E-Mail-Adresse]</p>
          </div>

          <div>
            <h2 className="font-semibold text-gray-900 mb-1">Verantwortlich für den Inhalt (§ 18 Abs. 2 MStV)</h2>
            <p>
              [Name]<br />
              [Straße und Hausnummer]<br />
              [Postleitzahl und Ort]
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
          Stand: September 2026
        </p>
      </div>
    </div>
  );
}
