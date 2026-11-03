# Balancing-Matrix: Helden gegen Bosse

Berechnung ohne Grafik (`python3 tools/balance.py e14`, Simulator `game/sim`). Jede Zelle: **Siegquote der Heldenseite** in Prozent bei 1 gegen 1 (Held gegen benannten Gegner), dazu auf jeder Seite zwei Büttel (Gruppenkampf), zufällige offene Karte, 60 Kämpfe je Zelle (Fehler etwa ±6 Prozentpunkte). In Klammern: Zeitüberschreitung in Prozent (der Kampf wurde in 40 Runden nicht entschieden, z. B. reine Heiler). Ziel für den Vergleich: etwa 50 % sind ausgewogen; deutlich darüber ist der Held zu stark gegen diesen Gegner, deutlich darunter zu schwach.

| Held \ Boss | Wart | Xiùlán | Oskar | Maja | Regent Morgrim | Stachelia | Wartens Frischlinge | Professor Kugelblitz | Cyborg-Wart | Ø Held |
|---|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| Mira & Brumm | 0% | 3% | 12% | 22% | 0% | 77% | 5% | 0% | 0% | **13%** |
| Ser Albrecht | 0% | 97% | 97% | 100% | 0% | 65% | 100% | 0% | 0% | **51%** |
| Takeda | 0% | 62% | 88% | 98% | 0% | 98% | 95% | 0% | 0% | **49%** |
| Meister Lin | 0% | 0% | 0% | 22% | 0% | 62% | 7% | 0% | 0% | **10%** |
| Die Kage-Schwestern | 0% | 0% | 0% | 13% | 0% | 35% | 68% | 0% | 0% | **13%** |
| Käpt’n Elisabeth | 0% | 5% | 10% | 25% | 0% | 40% | 17% | 0% | 0% | **11%** |
| Muskelaugust | 0% | 85% | 97% | 93% | 3% | 97% | 100% | 0% | 0% | **53%** |
| Robo | 98% | 100% | 100% | 100% | 58% | 100% | 100% | 25% | 0% | **76%** |
| Blauer Hundsfreund | 0% | 2% | 2% | 7% | 0% | 53% | 3% | 0% | 0% | **7%** |
| Wendy Wolle | 0% | 0% | 0% | 2% | 0% | 10% | 0% | 0% | 0% | **1%** |
| Claude | 0% | 2% | 23% | 0% | 0% | 25% | 28% | 0% | 0% | **9%** |
| Brunhilde Bräu | 0% | 83% | 95% | 100% | 0% | 98% | 100% | 0% | 0% | **53%** |
| Lumi Sternenglanz | 0% | 0% | 0% | 3% | 0% | 18% | 0% | 0% | 0% | **2%** |
| Dr. Humbug | 0% | 0% | 0% | 0% | 0% | 18% | 0% | 0% | 0% | **2%** |
| Robina | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 90% | 0% | **88%** |
| Stachelia | 0% | 2% | 10% | 33% | 0% | 45% | 17% | 0% | 0% | **12%** |
| **Ø Boss (Heldensieg)** | **12%** | **34%** | **40%** | **45%** | **10%** | **59%** | **46%** | **7%** | **0%** | |

## Auffälligkeiten

- **Stärkste Helden (Ø Siegquote):** Robina 88%, Robo 76%, Brunhilde Bräu 53%, Muskelaugust 53%
- **Schwächste Helden:** Blauer Hundsfreund 7%, Lumi Sternenglanz 2%, Dr. Humbug 2%, Wendy Wolle 1%
- **Stärkste Bosse (Helden gewinnen am seltensten):** Cyborg-Wart 100% Bosssieg, Professor Kugelblitz 93% Bosssieg, Regent Morgrim 90% Bosssieg
- **Schwächste Bosse:** Maja 55% Bosssieg, Wartens Frischlinge 54% Bosssieg, Stachelia 41% Bosssieg

