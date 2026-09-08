# Item <item-id>

> Vorlage. Kopieren, jedes Feld füllen, dann `python scripts/check_item_quality.py`.
> Die Regeln stehen in [14-itemregeln.md](../14-itemregeln.md), die Darstellungsschlüssel
> in [15-darstellungen.md](../15-darstellungen.md). `TEMPLATE.md` selbst wird vom Checker
> übersprungen.

- **item-id:** verdoppeln-halbieren.ZR20-01
- **konstrukt:** verdoppeln-halbieren.ZR20
- **zelle:** verdoppeln-halbieren × ZR20 × symbolisch
- **darstellung:** keine
- **darstellung-konfiguration:** —
- **blitz:** nein
- **prompt:** Rechne: 8 + 8
- **audio:** audio/v2/verdoppeln-halbieren.ZR20-01.mp3
- **antwortfelder:**
  - `ergebnis` — Ergebnis
- **erwartete-antwort:**
  - `ergebnis` = 16
- **fehlersignatur:**
  - `15` — ±1 nach unten: zählend gerechnet, ein Schritt zu wenig
  - `17` — ±1 nach oben: zählend gerechnet, ein Schritt zu viel
  - `10` — die Verdopplung wird als Ergänzung zur Zehn missdeutet
- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Gaidoschik, Automatisierung der Kernaufgaben
- **eigenstaendigkeit:** Zahlenpaar, Wortlaut und Antwortlayout eigenständig gewählt; kein bestehendes Instrument als Vorlage.
- **reviewer:** —
