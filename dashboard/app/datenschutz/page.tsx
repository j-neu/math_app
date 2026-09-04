import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Datenschutzerklärung – Numeris",
};

export default function DatenschutzPage() {
  return (
    <div className="min-h-screen bg-white">
      <div className="max-w-2xl mx-auto px-6 py-12">
        <Link href="/dashboard" className="text-sm text-gray-400 hover:text-gray-700 mb-8 inline-block">
          ← Zurück zum Dashboard
        </Link>

        <h1 className="text-2xl font-bold text-gray-900 mb-8">Datenschutzerklärung</h1>

        <div className="space-y-8 text-gray-700 text-sm leading-relaxed">

          <section>
            <h2 className="font-semibold text-gray-900 mb-2">1. Verantwortliche Stelle</h2>
            <p>
              Verantwortlich im Sinne der DSGVO ist:
            </p>
            {/* TODO: Real name and address eintragen, bevor diese Seite veröffentlicht wird. */}
            <p className="mt-2">
              [Name]<br />
              [Straße und Hausnummer], [Postleitzahl und Ort]<br />
              E-Mail: [E-Mail-Adresse]
            </p>
          </section>

          <section>
            <h2 className="font-semibold text-gray-900 mb-2">2. Zweck und Rechtsgrundlage der Verarbeitung</h2>
            <p>
              Numeris ist ein Diagnose-Werkzeug für Grundschullehrkräfte.
              Es werden ausschließlich folgende personenbezogene Daten verarbeitet:
            </p>
            <ul className="list-disc ml-5 mt-2 space-y-1">
              <li>
                <strong>Lehrkräfte:</strong> E-Mail-Adresse und Passwort-Hash (für die Anmeldung),
                Anzeigename, Schule. Rechtsgrundlage: berechtigtes Interesse (Art. 6 Abs. 1 lit. f DSGVO)
                bzw. Einwilligung (Art. 6 Abs. 1 lit. a DSGVO).
              </li>
              <li>
                <strong>Schülerinnen und Schüler:</strong> Pseudonymisierter Anzeigename
                (z. B. „S01", von der Lehrkraft gewählt), Klasse, Diagnoseergebnisse,
                generierter Förderplan sowie Fortschritt auf dem Lernpfad
                (bearbeitete Übungen, Antworten und erzielter Lernstand).
                Es werden keine vollständigen Namen, keine Geburtsdaten
                und keine direkten Identifikationsmerkmale gespeichert.
                Rechtsgrundlage: berechtigtes Interesse der Schule an der individuellen
                Förderung (Art. 6 Abs. 1 lit. f DSGVO).
              </li>
            </ul>
          </section>

          <section>
            <h2 className="font-semibold text-gray-900 mb-2">3. Datenverarbeitung und Hosting</h2>
            <p>
              Alle Daten werden ausschließlich auf Servern in der Europäischen Union verarbeitet
              und gespeichert. Als Auftragsverarbeiter wird <strong>Supabase</strong> eingesetzt
              (Rechenzentrum: Frankfurt am Main, Deutschland). Mit Supabase besteht ein
              Auftragsverarbeitungsvertrag (AVV) gemäß Art. 28 DSGVO.
            </p>
            <p className="mt-2">
              Das Lehrer-Dashboard wird auf Servern in der EU gehostet.
            </p>
          </section>

          <section>
            <h2 className="font-semibold text-gray-900 mb-2">4. Cookies und lokale Speicherung</h2>
            <p>
              Diese Anwendung verwendet ausschließlich technisch notwendige Cookies:
            </p>
            <ul className="list-disc ml-5 mt-2 space-y-1">
              <li>
                <strong>Sitzungs-Cookie</strong> (Supabase Auth): Speichert den Anmelde-Status
                der Lehrkraft für die Dauer der Sitzung. Ohne dieses Cookie ist eine Anmeldung
                nicht möglich.
              </li>
            </ul>
            <p className="mt-2">
              Es werden keine Tracking-, Marketing- oder Analyse-Cookies eingesetzt.
              Es werden keine Daten an Dritte zu Werbezwecken weitergegeben.
            </p>
          </section>

          <section>
            <h2 className="font-semibold text-gray-900 mb-2">5. Speicherdauer</h2>
            <p>
              Diagnosedaten werden für die Dauer des Schuljahres bzw. bis zur Löschung durch
              die verantwortliche Lehrkraft oder Schulverwaltung gespeichert.
              Lehrerkonten und alle zugehörigen Schüler- und Diagnosedaten werden auf Anfrage
              vollständig gelöscht (siehe Abschnitt 7).
            </p>
          </section>

          <section>
            <h2 className="font-semibold text-gray-900 mb-2">6. Weitergabe an Dritte</h2>
            <p>
              Eine Weitergabe personenbezogener Daten an Dritte erfolgt nicht, es sei denn,
              dies ist zur Vertragserfüllung erforderlich (Supabase als Auftragsverarbeiter)
              oder gesetzlich vorgeschrieben.
            </p>
          </section>

          <section>
            <h2 className="font-semibold text-gray-900 mb-2">7. Ihre Rechte (Art. 15–22 DSGVO)</h2>
            <p>Sie haben das Recht auf:</p>
            <ul className="list-disc ml-5 mt-2 space-y-1">
              <li>Auskunft über die zu Ihrer Person gespeicherten Daten (Art. 15)</li>
              <li>Berichtigung unrichtiger Daten (Art. 16)</li>
              <li>Löschung Ihrer Daten („Recht auf Vergessenwerden", Art. 17)</li>
              <li>Einschränkung der Verarbeitung (Art. 18)</li>
              <li>Datenübertragbarkeit (Art. 20)</li>
              <li>Widerspruch gegen die Verarbeitung (Art. 21)</li>
            </ul>
            <p className="mt-2">
              Zur Ausübung Ihrer Rechte wenden Sie sich bitte per E-Mail an die im
              Impressum genannte Adresse. Anfragen werden innerhalb von 30 Tagen
              bearbeitet.
            </p>
            <p className="mt-2">
              Sie haben außerdem das Recht, sich bei der zuständigen Datenschutz-Aufsichtsbehörde
              zu beschweren. Für Berlin ist dies:{" "}
              <strong>Berliner Beauftragte für Datenschutz und Informationsfreiheit</strong>,{" "}
              <a
                href="https://www.datenschutz-berlin.de"
                target="_blank"
                rel="noopener noreferrer"
                className="underline hover:text-gray-900"
              >
                www.datenschutz-berlin.de
              </a>.
            </p>
          </section>

          <section>
            <h2 className="font-semibold text-gray-900 mb-2">8. Auftragsverarbeitungsvertrag (AVV)</h2>
            <p>
              Schulen, die Numeris einsetzen, schließen mit dem Anbieter einen
              Auftragsverarbeitungsvertrag gemäß Art. 28 DSGVO ab. Dieser regelt,
              dass personenbezogene Daten ausschließlich im Auftrag und nach Weisung
              der verantwortlichen Schule verarbeitet werden.
              {/* TODO: Add link to AVV document once finalized */}
            </p>
          </section>

        </div>

        <p className="mt-12 text-xs text-gray-400">
          Stand: September 2026
        </p>
      </div>
    </div>
  );
}
