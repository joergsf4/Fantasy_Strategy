# Balancing: Gruppen gegen Bosse

Berechnung ohne Grafik (`python3 tools/balance.py e15`). Zufällige Gruppen aus den 15 Helden (ohne Stachelia) gegen **einen benannten Gegner plus zwei Büttel**, zufällige offene Karte. Siegquote der Heldengruppe.

## 1. Wie viele Helden braucht man gegen einen Boss?

| Boss | 3 Helden | 4 Helden | 5 Helden | 6 Helden |
|---|--:|--:|--:|--:|
| Wart | 80% | 98% | 100% | 100% |
| Xiùlán | 98% | 100% | 100% | 100% |
| Oskar | 100% | 100% | 100% | 100% |
| Maja | 99% | 100% | 100% | 100% |
| Regent Morgrim | 64% | 94% | 99% | 100% |
| Stachelia | 100% | 100% | 100% | 100% |
| Wartens Frischlinge | 100% | 100% | 100% | 100% |
| Professor Kugelblitz | 49% | 80% | 97% | 100% |
| Cyborg-Wart | 16% | 46% | 77% | 94% |

## 2. Beitrag der Helden (Gruppen aus vier Helden)

Zelle: Siegquote aller Vierergruppen, in denen dieser Held mitkämpft, gegen diesen Boss (etwa 240 Kämpfe je Zelle, Fehler ±4 Punkte). Letzte Spalte: Abstand zum Durchschnitt aller Helden in Prozentpunkten (positiv = Gruppen mit diesem Helden gewinnen häufiger).

| Held \ Boss | Wart | Xiùlán | Oskar | Maja | Regent Morgrim | Stachelia | Wartens Frischlinge | Professor Kugelblitz | Cyborg-Wart | Ø | Abstand |
|---|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| Robina | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 89% | **99%** | +8 |
| Robo | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 86% | **98%** | +7 |
| Muskelaugust | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 92% | 56% | **94%** | +3 |
| Takeda | 99% | 100% | 100% | 100% | 98% | 100% | 100% | 89% | 51% | **93%** | +2 |
| Ser Albrecht | 99% | 100% | 100% | 100% | 98% | 100% | 100% | 84% | 46% | **92%** | +1 |
| Brunhilde Bräu | 100% | 100% | 100% | 100% | 96% | 100% | 100% | 84% | 42% | **91%** | +0 |
| Dr. Humbug | 98% | 100% | 100% | 100% | 93% | 100% | 100% | 78% | 46% | **91%** | -0 |
| Lumi Sternenglanz | 97% | 100% | 100% | 100% | 92% | 100% | 100% | 78% | 45% | **90%** | -1 |
| Meister Lin | 98% | 100% | 100% | 100% | 93% | 100% | 100% | 79% | 38% | **90%** | -1 |
| Blauer Hundsfreund | 98% | 100% | 100% | 100% | 90% | 100% | 100% | 73% | 37% | **89%** | -2 |
| Wendy Wolle | 97% | 100% | 100% | 100% | 91% | 100% | 100% | 71% | 35% | **88%** | -3 |
| Mira & Brumm | 97% | 100% | 100% | 100% | 88% | 100% | 100% | 74% | 35% | **88%** | -3 |
| Käpt’n Elisabeth | 99% | 100% | 100% | 100% | 92% | 100% | 100% | 69% | 32% | **88%** | -3 |
| Claude | 98% | 100% | 100% | 100% | 94% | 100% | 100% | 67% | 29% | **88%** | -3 |
| Die Kage-Schwestern | 94% | 100% | 100% | 100% | 87% | 100% | 100% | 70% | 27% | **86%** | -5 |

## Auffälligkeiten

- **Größter Beitrag:** Robina (+8), Robo (+7), Muskelaugust (+3), Takeda (+2)
- **Kleinster Beitrag:** Mira & Brumm (-3), Käpt’n Elisabeth (-3), Claude (-3), Die Kage-Schwestern (-5)
- **Härteste Bosse selbst mit sechs Helden:** Cyborg-Wart 94%, Professor Kugelblitz 100%, Wart 100%
- **Leichteste Bosse mit vier Helden:** Xiùlán 100%, Oskar 100%, Maja 100%

