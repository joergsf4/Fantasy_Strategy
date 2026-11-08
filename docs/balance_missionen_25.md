
## 16. Gruppenvielfalt je Mission (E17)

`python3 tools/balance.py e17`. Je Mission bis zu 60 zufällige, regelkonforme Gruppen: die **festen Story-Plätze** bleiben, der Rest kommt aus allen bis dahin bekannten Helden. Jede Gruppe kämpft 16-mal mit den erwarteten **Talentpunkten** und der erwarteten **Ausrüstung** gegen die Gegner der Karte (Faktoren aus `progression.json`). Gemessen mit der Simulations-KI; Sonderziele (Tor in Mission 2, Geisel in 4, Kinder befreien in 13, Feuer in 14, Wolfsangst in 17) kennt sie nicht, dort zählt „alle Gegner besiegt“. Nicht gemessen: Missionen 2, 4, 11, 13.

| Mission | feste Plätze | Gruppen | Ziel | Ø Siegquote | schlechteste 10 % der Gruppen | schlechteste Gruppe | Gruppen unter Ziel−15 % |
|---|---|--:|--:|--:|--:|--:|--:|
| 25 | Mira & Brumm, Stachelia, Blauer Hundsfreund | 60 | 80% | 100% | 97% | 94% | 0 (0%) |

### Schlechteste Gruppen je Mission

- **Mission 25:** 94%: Mira & Brumm, Stachelia, Blauer Hundsfreund, Brunhilde Bräu, Dr. Humbug, Wendy Wolle; 94%: Mira & Brumm, Stachelia, Blauer Hundsfreund, Käpt’n Elisabeth, Dr. Humbug, Wendy Wolle; 94%: Mira & Brumm, Stachelia, Blauer Hundsfreund, Lumi Sternenglanz, Dr. Humbug, Wendy Wolle

### Beitrag der Helden (Siegquote der Gruppen mit dem Helden minus Durchschnitt, in Prozentpunkten)

| Held | M25 |
|---|--:|
| Blauer Hundsfreund | +0 |
| Brunhilde Bräu | -0 |
| Die Kage-Schwestern | +0 |
| Dr. Humbug | -1 |
| Käpt’n Elisabeth | -0 |
| Lumi Sternenglanz | -0 |
| Meister Lin | +0 |
| Mira & Brumm | +0 |
| Muskelaugust | +0 |
| Robina | +0 |
| Robo | +0 |
| Ser Albrecht | +0 |
| Stachelia | +0 |
| Takeda | +0 |
| Wendy Wolle | -1 |
