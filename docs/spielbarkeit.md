# Spielbarkeit aller Missionen

Erzeugt von `tools/spielbarkeit.py` am 13.11.2026 (Stand `5ce9a0d`), 2541 Kämpfe.
Ein Bot (`game/scripts/bot/`) spielt den echten Kampf über dieselben Klicks und Menüknöpfe wie ein Mensch, Schwierigkeit „Normal“. Jede Variante läuft mit bis zu drei Spielstilen (normal, vorsichtig, forsch) und gilt als **schaffbar**, wenn ein Stil gewinnt. **Ein Bot-Sieg beweist, dass die Mission schaffbar ist; eine Bot-Niederlage beweist nicht das Gegenteil**, der Bot ist schwächer als ein Mensch.

## Übersicht

| Mission | Standard | Gruppen | ohne / beste Ausrüstung | Talente (−1 / 0 / Angriff) | ohne einzelne Fähigkeit | Sonderfälle |
|---|---|--:|---|---|--:|---|
| ch1 Eichenfurt in Gefahr | ✓ 4 R. | – | ✓ / ✓ | – / – / – | 12/12 | 2/2 |
| ch2 Der Hohlweg | ✓ 4 R. | 9/9 | ✓ / ✓ | – / – / – | 12/12 | 3/3 |
| ch3 Mühlbach in Flammen | ✓ 8 R. | 20/20 | ✓ / ✓ | – / – / – | 12/12 | 3/3 |
| rb_takeda Rückblende: Takeda und die Kage-Schwestern | ✓ 3 R. | – | ✓ / ✓ | ✓ / ✓ / ✓ | 2/2 | 3/3 |
| ch4 Das Teehaus am Pass | ✓ 3 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 12/12 | 3/3 |
| ch5 Stachelias Rückkehr | ✓ 4 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 12/12 | 3/3 |
| ch6 Möwenbucht | ✓ 4 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 13/13 | 3/3 |
| ch7 Sandhafen | ✓ 5 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 12/12 | 3/3 |
| ch8 Die bewachte Oase | ✓ 12 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 12/12 | 3/3 |
| ch9 Die Festung im Gebirge | ✓ 3 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 12/12 | 3/3 |
| ch11 Stachelias Stand | ✓ 9 R. | – | ✓ / ✓ | ✓ / ✓ / ✓ | 2/2 | 3/3 |
| ch12 Die hochgezogene Brücke | ✓ 6 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 12/12 | 3/3 |
| ch13 Das Labor im Wald | ✓ 5 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 12/12 | 3/3 |
| ch14 Das brennende Waisenhaus | ✓ 5 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 10/10 | 3/3 |
| ch15 Der Sumpf vor den Bergen | ✓ 6 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 12/12 | 3/3 |
| ch16 Streit um den Sold | ✓ 6 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 12/12 | 3/3 |
| ch18 Die Wölfe der Nacht | ✓ 4 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 12/12 | 3/3 |
| ch19 Der Regent im Schnee | ✓ 3 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 12/12 | 3/3 |
| ch20 Hogsmeat | ✓ 7 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 12/12 | 3/3 |
| ch21 Die Rechnung der Xiùlán | ✓ 3 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 8/8 | 3/3 |
| ch22 Die Zwergenmine | ✓ 3 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 12/12 | 3/3 |
| ch23 Zwischenspiel: Im Labor des Professors | ✓ 6 R. | – | ✓ / ✓ | ✓ / ✓ / ✓ | 1/1 | 3/3 |
| ch24 Das leere Labor | ✓ 6 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 12/12 | 3/3 |
| ch25 Der Thronsaal | ✓ 7 R. | 20/20 | ✓ / ✓ | ✓ / ✓ / ✓ | 12/12 | 3/3 |

## Warnungen

Keine: jede Variante wurde in mindestens einem Stil geschafft.

## Gruppen: schwächste Varianten je Mission

- **ch2:** 9/9 Gruppen geschafft
- **ch3:** 20/20 Gruppen geschafft
- **ch4:** 20/20 Gruppen geschafft
- **ch5:** 20/20 Gruppen geschafft
- **ch6:** 20/20 Gruppen geschafft
- **ch7:** 20/20 Gruppen geschafft
- **ch8:** 20/20 Gruppen geschafft
- **ch9:** 20/20 Gruppen geschafft
- **ch12:** 20/20 Gruppen geschafft
- **ch13:** 20/20 Gruppen geschafft
- **ch14:** 20/20 Gruppen geschafft
- **ch15:** 20/20 Gruppen geschafft
- **ch16:** 20/20 Gruppen geschafft
- **ch18:** 20/20 Gruppen geschafft
- **ch19:** 20/20 Gruppen geschafft
- **ch20:** 20/20 Gruppen geschafft
- **ch21:** 20/20 Gruppen geschafft
- **ch22:** 20/20 Gruppen geschafft
- **ch24:** 20/20 Gruppen geschafft
- **ch25:** 20/20 Gruppen geschafft

## Abdeckung der Fähigkeiten

Wie oft eine Heldenfähigkeit im Menü einsetzbar war (Kämpfe) und wie oft der Bot sie benutzt hat.

| Fähigkeit | einsetzbar (Kämpfe) | benutzt |
|---|--:|--:|
| Bärengebrüll | 2191 | 1202 |
| Bärenpranke | 2082 | 2296 |
| Bearhug | 459 | 521 |
| Bellen | 1702 | 1008 |
| Verstärkung | 669 | 8 |
| Breitseite | 342 | 651 |
| Dampframme | 222 | 11 |
| Fasswurf | 597 | 1279 |
| Giftstachel | 656 | 1325 |
| Grüner Laser | 1206 | 939 |
| Gruppenheilung | 1413 | 146 |
| Heulen | 0 | 0 |
| Hinterhältiger Angriff | 621 | 454 |
| Kanone | 1303 | 1604 |
| Kehlbiss | 0 | 0 |
| Knochenwurf | 1699 | 2724 |
| Kyujutsu | 726 | 608 |
| Prost | 528 | 66 |
| Roter Laser | 1213 | 2261 |
| Schlachtruf | 1536 | 2570 |
| Stabsprung | 576 | 126 |
| Stabwirbel | 585 | 785 |
| Sternensegen | 328 | 151 |
| Sternschnuppe | 384 | 811 |
| Todeswirbel | 726 | 922 |
| Tonikum | 588 | 877 |
| Verspotten | 1536 | 1076 |
| Versteck | 648 | 190 |
| Wollmantel | 1413 | 2913 |
| Wundersalbe | 496 | 595 |
| Wurf | 468 | 34 |
| Arrr! Wutanfall | 1326 | 356 |

- **Nie benutzt** (aber einsetzbar): keine
- **Nie einsetzbar** (kein gültiges Ziel oder Held nie dabei): Heulen, Kehlbiss

## Objekte, Aktionen und Gegenstände

- Menü-Aktionen: Befreien ×921, Fesseln lösen ×278, Glocke läuten ×118, Honig einfüllen ×123, Schalter umlegen ×53, Truhe öffnen ×408, Umprogrammieren ×341
- Gegenstände: aether ×2325, bier ×79, gegengift ×670, heilhonig ×69, heiltrank ×3433, rauchbombe ×36
- Geheimnisse: keine (der Bot löst Geheimnisse nicht gezielt aus)

## Planabweichungen und Hänger

0 Planabweichungen (Bot wollte etwas, das das Menü nicht anbot), 0 Hänger, Schleifen oder Zeitlimits.


Kampfzeit gesamt 123 min (auf 9 Prozesse verteilt).
