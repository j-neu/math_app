import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Wissenschaftliche Grundlagen – Numeris",
  description:
    "Numeris wird auf der Grundlage der mathematikdidaktischen Forschung zur Prävention von Rechenschwierigkeiten entwickelt. Hier finden Sie die zugrunde liegende Fachliteratur in wissenschaftlicher Zitierweise.",
};

export default function WissenschaftlicheGrundlagenPage() {
  return (
    <div className="min-h-screen bg-white">
      <div className="max-w-2xl mx-auto px-6 py-12">
        <Link href="/dashboard" className="text-sm text-gray-400 hover:text-gray-700 mb-8 inline-block">
          ← Zurück zum Dashboard
        </Link>

        <h1 className="text-2xl font-bold text-gray-900 mb-8">Wissenschaftliche Grundlagen</h1>

        <div className="space-y-8 text-gray-700 text-sm leading-relaxed">
          <section>
            <p>
              Numeris wird auf der Grundlage der aktuellen mathematikdidaktischen Forschung
              zur Prävention von Rechenschwierigkeiten entwickelt. Die folgende Literatur
              begründet die erfassten Konstrukte (Zählkompetenz, Anzahlerfassung,
              Zahlzerlegung, Stellenwertverständnis, Rechenstrategien und Sachsituationen),
              die Schwierigkeitsabstufung der Aufgaben sowie die Logik der Förderplanung
              (Ist-Stand, Ziele und Lernweg). Die Angaben erfolgen in der üblichen
              wissenschaftlichen Zitierweise als Quellenangabe gemäß § 51 UrhG.
            </p>
          </section>

          <section>
            <h2 className="font-semibold text-gray-900 mb-3">A. Kernbibliographie (Bücher)</h2>
            <ul className="list-disc ml-5 space-y-3">
              <li>
                Padberg, F. &amp; Benz, C. (2021). <em>Didaktik der Arithmetik. fundiert, vielseitig,
                praxisnah</em> (5., überarbeitete Auflage). Berlin/Heidelberg: Springer Spektrum.
              </li>
              <li>
                Wartha, S. &amp; Schulz, A. (2019). <em>Rechenproblemen vorbeugen. 2.–4. Klasse</em>
                (6. Auflage). Lehrerbücherei Grundschule. Berlin: Cornelsen.
              </li>
              <li>
                Selter, C. &amp; Spiegel, H. (1997). <em>Wie Kinder rechnen</em> (Programm Mathe 2000).
                Leipzig/Stuttgart/Düsseldorf: Ernst Klett Grundschulverlag.
              </li>
              <li>
                Schipper, W. (2009). <em>Handbuch für den Mathematikunterricht an Grundschulen</em>.
                Braunschweig: Schroedel / Westermann.
              </li>
            </ul>
          </section>

          <section>
            <h2 className="font-semibold text-gray-900 mb-3">B. Frei verfügbare offizielle Ergänzungen</h2>
            <ul className="list-disc ml-5 space-y-3">
              <li>
                Kultusministerkonferenz (2022; ursprünglich 2004). <em>Bildungsstandards im Fach
                Mathematik für den Primarbereich</em>. Berlin.{" "}
                <a
                  href="https://www.kmk.org/fileadmin/Dateien/veroeffentlichungen_beschluesse/2022/2022_06_23-Bista-Primarbereich-Mathe.pdf"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="underline hover:text-gray-900"
                >
                  Verfügbar unter
                </a>
                .
              </li>
              <li>
                Senatsverwaltung für Bildung, Jugend und Familie Berlin &amp; Ministerium für Bildung,
                Jugend und Sport des Landes Brandenburg (2015, überarbeitet 2023).{" "}
                <em>Rahmenlehrplan für die Jahrgangsstufen 1–10, Teil C Mathematik</em>. Berlin.{" "}
                <a
                  href="https://bildungsserver.berlin-brandenburg.de/fileadmin/bbb/unterricht/rahmenlehrplaene/Rahmenlehrplanprojekt/amtliche_Fassung/Teil_C_Mathematik_2015_10_13_Ma_14.08.2023_Berlin_23_11.pdf"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="underline hover:text-gray-900"
                >
                  Verfügbar unter
                </a>
                .
              </li>
              <li>
                Krajewski, K. (2003/2008). <em>Vorhersage von Rechenschwäche in der Grundschule</em>
                (Studien zur Kindheits- und Jugendforschung, Bd. 29). Hamburg: Verlag Dr. Kovač.
              </li>
              <li>
                Moser Opitz, E. (2013, 2. Aufl.). <em>Rechenschwäche/Dyskalkulie. Theoretische
                Klärungen und empirische Studien an betroffenen Schülerinnen und Schülern</em>.
                Bern: Haupt.
              </li>
              <li>
                Gaidoschik, M. (2010). <em>Die Entwicklung von Lösungsstrategien zu den additiven
                Grundaufgaben im Laufe des ersten Schuljahres</em> (Dissertation, Universität Wien).
                Wien: Universität Wien.{" "}
                <a
                  href="https://utheses.univie.ac.at/detail/8253"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="underline hover:text-gray-900"
                >
                  Verfügbar unter
                </a>
                .
              </li>
            </ul>
          </section>

          <section>
            <h2 className="font-semibold text-gray-900 mb-3">C. Frei zugängliche Äquivalente</h2>
            <ul className="list-disc ml-5 space-y-3">
              <li>
                Gaidoschik, M., Moser Opitz, E., Nührenbörger, M. &amp; Rathgeb-Schnierer, E. (2021).
                <em> Besondere Schwierigkeiten beim Mathematiklernen</em> (GDM-Sonderausgabe).{" "}
                <a
                  href="https://ojs.didaktik-der-mathematik.de/index.php/mgdm/issue/view/46"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="underline hover:text-gray-900"
                >
                  Verfügbar unter
                </a>
                .
              </li>
              <li>
                Prediger, S. &amp; Selter, C. (o. J.). <em>Mathe sicher können</em> (Deutsches Zentrum
                für Lehrerbildung Mathematik, DZLM).{" "}
                <a
                  href="https://mathe-sicher-koennen.dzlm.de"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="underline hover:text-gray-900"
                >
                  Verfügbar unter
                </a>
                .
              </li>
              <li>
                Deutsches Zentrum für Lehrerbildung Mathematik (o. J.). <em>KIRA – Online-Plattform zu
                Rechenstrategien von Kindern</em>.{" "}
                <a
                  href="https://kira.dzlm.de"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="underline hover:text-gray-900"
                >
                  Verfügbar unter
                </a>
                .
              </li>
              <li>
                Deutsches Zentrum für Lehrerbildung Mathematik (o. J.). <em>Mahiko – Materialien zu
                Zählen, Zehner/Einer, Zahlzerlegung und zum Zahlenraum bis 1000</em>.{" "}
                <a
                  href="https://mahiko.dzlm.de"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="underline hover:text-gray-900"
                >
                  Verfügbar unter
                </a>
                .
              </li>
              <li>
                Karner (o. J.). <em>Zahlzerlegungen im Zahlenraum 10</em> (Universität Wien,
                Projekt Mathe macht Freude).{" "}
                <a
                  href="https://mmf.univie.ac.at/fileadmin/user_upload/p_mathematikmachtfreunde/MmF-Primar/Artikel-Zahlzerlegungen-Zahlenraum-10.pdf"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="underline hover:text-gray-900"
                >
                  Verfügbar unter
                </a>
                .
              </li>
              <li>
                Lenz &amp; Wittmann (2023). <em>Zur Erarbeitung des Teile-Ganzes-Konzepts im
                mathematischen Anfangsunterricht</em> (JMD, open access).{" "}
                <a
                  href="https://link.springer.com/article/10.1007/s13138-023-00218-0"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="underline hover:text-gray-900"
                >
                  Verfügbar unter
                </a>
                .
              </li>
            </ul>
          </section>

          <p className="text-xs text-gray-400">
            Stand: August 2026. Alle Angaben dienen ausschließlich der Kennzeichnung der
            wissenschaftlichen Grundlagen des Diagnose-Werkzeugs (§ 51 UrhG).
          </p>
        </div>
      </div>
    </div>
  );
}
