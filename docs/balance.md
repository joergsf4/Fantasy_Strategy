# Balancing-Bericht

Erzeugt von `tools/balance.py` mit dem grafikfreien Simulator (`game/sim/`). Er nutzt dieselben Regeln wie das Spiel (Parität per `tests/test_sim.gd` geprüft) und lässt beide Seiten von derselben einfachen KI spielen. Die Zahlen zeigen **relative Stärke**, nicht das Verhalten menschlicher Spieler.

## Kurzfassung

- Stärkste Gruppenbeiträge: Robo (+37.8 Pp), Ser Albrecht (+4.3 Pp), Takeda (+1.5 Pp)
- Schwächste Gruppenbeiträge: Kage-Schwestern (-5.3 Pp), Mira & Brumm (-6.0 Pp), Meister Lin (-7.9 Pp)
- Sehr starke Fähigkeiten (> +6 Pp): Roter Laser (+25.5), Schlachtruf (+13.0), Todeswirbel (+11.7), Knochenwurf (+6.3), Fasswurf (+6.2)
- Kaum messbarer Nutzen (< +1 Pp oder im Rauschen): Polymorph (-0.1), Stabsprung (+0.1), Grüner Laser (+1.1), Wurf (+1.3), Gruppenheilung (+1.5), Verspotten (+1.8), Versteck (+2.3), Giftstachel (+3.1), Bärenpranke (+4.3)
- Stärkemodell: Trefferquote 95%; höchste Heldenwerte Robo (+24.8), Ser Albrecht (+11.3), Takeda (+10.2)
- Ausrüstung: stärkstes Stück Plattenpanzer (+8.4 Pp), schwächstes Magierrobe (-0.0 Pp)
- Kapitel-1-Ausstattung hebt die Siegquote um +19.1 Pp
- Verteidigen: Gruppen +3.2 Pp Siegquote, 16.5 Einsätze pro Kampf
- Mission 3: ohne Löschen gehen im Schnitt 4.0 von 4 Häusern verloren, mit voller Löschung 0.1
- Mission 5: bei ×1,0 gewinnt die Gruppe 100%, Kinder werden in 27% der Kämpfe gestochen (ohne Glocke und Stöcke: 94% / 77%)
- Mission 6: bei ×1,0 gewinnt die Gruppe 100% in 6.5 Runden (ohne Breitseite 100%)
- Warten (wachsam, +2 Angriff): Siegquote 61.0% gegen 62.9% ohne Bonus (Verteidigen an)
- Mission 7: bei ×1,0 gewinnt die Gruppe mit den neuen Heilern 100% (mit Wendy und Robo 100%)

## 1. Einzelwertung: Wert in Infanteristen

Wie viele Infanteristen schlägt die Figur allein mit 50 % Siegquote? (Karte zufällig, KI wie im Spiel.)

| Figur | Wert (Infanteristen) | Siegquote gegen 1 / 3 / 6 |
|---|--:|---|
| Robo | 29.0 | 100% / 100% / 100% |
| Takeda | 25.8 | 100% / 100% / 100% |
| Brunhilde Bräu | 13.9 | 100% / 100% / 100% |
| Ser Albrecht | 9.6 | 100% / 100% / 100% |
| Muskelaugust | 9.3 | 100% / 100% / 97% |
| Blauer Hundsfreund | 6.3 | 100% / 100% / 56% |
| Mira & Brumm | 5.6 | 100% / 100% / 40% |
| Claude | 5.0 | 100% / 96% / 28% |
| Käpt’n Elisabeth | 3.6 | 100% / 84% / 3% |
| Stachelia | 3.1 | 100% / 53% / 2% |
| Meister Lin | 3.0 | 99% / 49% / 4% |
| Kage-Schwestern | 2.5 | 100% / 23% / 7% |
| Reiter | 1.7 | 98% / 6% / 0% |
| Wendy Wolle | 1.5 | 100% / 2% / 0% |
| Infanterie | 1.0 | 52% / 1% / 0% |
| Bogenschütze | 0.1 | 4% / 0% / 0% |
| Priester | 0.1 | 1% / 0% / 0% |

Unterstützer (Heiler) haben allein kaum Wert; ihr Beitrag zeigt sich erst in der Gruppe (siehe 2.).

## 2. Beitrag zur Gruppe

Zufällige 6er-Gruppen aus allen 13 Helden gegen 12 Soldaten (Standardmischung, Leben und Angriff ×1.5). Gesamt-Siegquote 57.9% bei 4000 Kämpfen. „Δ Sieg“ = Siegquote mit dem Helden minus Gesamtquote.

| Held | Δ Sieg | Überlebt | Schaden/Kampf | Erlitten/Kampf | Geheilt/Kampf | Besiegt/Kampf |
|---|--:|--:|--:|--:|--:|--:|
| Robo | +37.8 Pp ± 0.9 | 96% | 161 | 5 | 20 | 4.9 |
| Ser Albrecht | +4.3 Pp ± 2.2 | 56% | 44 | 22 | 0 | 1.4 |
| Takeda | +1.5 Pp ± 2.3 | 25% | 88 | 23 | 0 | 2.3 |
| Brunhilde Bräu | -0.5 Pp ± 2.3 | 39% | 69 | 31 | 0 | 1.9 |
| Muskelaugust | -2.9 Pp ± 2.3 | 39% | 37 | 31 | 0 | 1.4 |
| Wendy Wolle | -3.3 Pp ± 2.3 | 32% | 5 | 17 | 29 | 0.2 |
| Blauer Hundsfreund | -3.9 Pp ± 2.3 | 24% | 50 | 27 | 0 | 1.4 |
| Käpt’n Elisabeth | -4.0 Pp ± 2.3 | 33% | 45 | 15 | 0 | 1.5 |
| Claude | -5.2 Pp ± 2.3 | 32% | 33 | 13 | 0 | 1.2 |
| Stachelia | -5.2 Pp ± 2.3 | 17% | 21 | 19 | 0 | 0.7 |
| Kage-Schwestern | -5.3 Pp ± 2.3 | 31% | 29 | 16 | 0 | 1.3 |
| Mira & Brumm | -6.0 Pp ± 2.4 | 21% | 40 | 33 | 0 | 0.9 |
| Meister Lin | -7.9 Pp ± 2.3 | 12% | 22 | 29 | 0 | 0.7 |

## 3. Wie stark ist jede Fähigkeit?

Gepaarter Vergleich: derselbe Held mit 5 Zufallshelden gegen denselben Verband (gleiche Karten und Gruppen), einmal mit, einmal ohne die Fähigkeit. „Δ Sieg“ ist der Siegquoten-Gewinn durch die Fähigkeit in Prozentpunkten (Pp). „Schaden/Heilung“ = pro Einsatz.

| Held | Fähigkeit | Δ Sieg | ± | Einsätze/Kampf | Schaden pro Einsatz | Heilung pro Einsatz | Status pro Einsatz | Abklingzeit |
|---|---|--:|--:|--:|--:|--:|--:|--:|
| Mira & Brumm | Bärenpranke | +4.3 Pp | 1.8 | 2.46 | 7.3 | 0.0 | 0.82 | 3 |
| Ser Albrecht | Schlachtruf | +13.0 Pp | 1.8 | 3.46 | 0.0 | 0.0 | 2.94 | 4 |
| Ser Albrecht | Verspotten | +1.8 Pp | 1.8 | 3.37 | 0.0 | 0.0 | 3.39 | 4 |
| Takeda | Todeswirbel | +11.7 Pp | 1.8 | 2.43 | 25.9 | 0.0 | 1.00 | 3 |
| Meister Lin | Stabsprung | +0.1 Pp | 1.8 | 0.03 | 2.9 | 0.0 | 0.00 | 2 |
| Kage-Schwestern | Versteck | +2.3 Pp | 1.8 | 3.06 | 0.0 | 0.0 | 1.00 | 4 |
| Käpt’n Elisabeth | Kanone | +5.2 Pp | 1.8 | 2.62 | 11.1 | 0.0 | 0.00 | 3 |
| Muskelaugust | Wurf | +1.3 Pp | 1.8 | 1.28 | 3.2 | 0.0 | 0.89 | 4 |
| Robo | Roter Laser | +25.5 Pp | 1.3 | 4.94 | 24.5 | 0.0 | 0.00 | 3 |
| Robo | Grüner Laser | +1.1 Pp | 0.8 | 1.94 | 0.0 | 9.8 | 0.00 | 2 |
| Blauer Hundsfreund | Knochenwurf | +6.3 Pp | 1.8 | 3.21 | 7.3 | 0.0 | 0.00 | 2 |
| Wendy Wolle | Gruppenheilung | +1.5 Pp | 1.8 | 1.09 | 0.0 | 6.4 | 0.00 | 3 |
| Claude | Polymorph | -0.1 Pp | 1.8 | 1.79 | 0.0 | 0.0 | 1.00 | 5 |
| Stachelia | Giftstachel | +3.1 Pp | 1.8 | 2.77 | 3.2 | 0.0 | 0.98 | 2 |
| Brunhilde Bräu | Fasswurf | +6.2 Pp | 1.8 | 4.11 | 6.3 | 0.0 | 0.79 | 3 |

### Alle Fähigkeiten eines Helden abgeschaltet

Zeigt, wie viel die Spezialfähigkeiten insgesamt zum Helden beitragen (nur normaler Angriff bleibt).

| Held | Δ Sieg durch alle Fähigkeiten | ± |
|---|--:|--:|
| Mira & Brumm | +4.3 Pp | 1.8 |
| Ser Albrecht | +13.9 Pp | 1.8 |
| Takeda | +11.7 Pp | 1.8 |
| Meister Lin | +0.1 Pp | 1.8 |
| Kage-Schwestern | +2.3 Pp | 1.8 |
| Käpt’n Elisabeth | +5.2 Pp | 1.8 |
| Muskelaugust | +1.3 Pp | 1.8 |
| Robo | +32.8 Pp | 1.3 |
| Blauer Hundsfreund | +6.3 Pp | 1.8 |
| Wendy Wolle | +1.5 Pp | 1.8 |
| Claude | -0.1 Pp | 1.8 |
| Stachelia | +3.1 Pp | 1.8 |
| Brunhilde Bräu | +6.2 Pp | 1.8 |

## 4. Schwierigkeit Kapitel 1

Aufstellung wie im Spiel (6 Helden gegen 5 Gegner). Siegquote der Spielergruppe, wenn die Gegner entsprechend stärker (Leben und Angriff) werden:

| Gegner-Faktor | Siegquote | Ø Runden | Überlebende Helden |
|--:|--:|--:|--:|
| ×0.6 | 100% | 5.9 | 100% |
| ×0.8 | 100% | 6.8 | 100% |
| ×1.0 | 100% | 7.2 | 100% |
| ×1.2 | 100% | 7.9 | 99% |
| ×1.4 | 100% | 8.7 | 98% |
| ×1.6 | 100% | 10.2 | 91% |
| ×1.8 | 100% | 11.5 | 81% |
| ×2.0 | 98% | 13.4 | 68% |
| ×2.2 | 83% | 14.8 | 53% |
| ×2.4 | 49% | 15.1 | 27% |
| ×2.6 | 13% | 14.5 | 6% |
| ×2.8 | 9% | 14.2 | 4% |
| ×3.0 | 2% | 13.6 | 1% |
| ×3.2 | 0% | 12.9 | 0% |
| ×3.4 | 0% | 12.7 | 0% |
| ×3.6 | 0% | 11.0 | 0% |
| ×3.8 | 0% | 10.3 | 0% |
| ×4.0 | 0% | 10.6 | 0% |
| ×4.2 | 0% | 10.5 | 0% |
| ×4.4 | 0% | 10.8 | 0% |

Zusätzliche Infanteristen (bei Faktor ×1,0):

| Zusätzliche Gegner | Siegquote | Überlebende Helden |
|--:|--:|--:|
| +0 | 100% | 100% |
| +1 | 100% | 100% |
| +2 | 100% | 100% |
| +3 | 100% | 100% |
| +4 | 100% | 100% |
| +5 | 100% | 100% |
| +6 | 100% | 99% |
| +7 | 100% | 99% |
| +8 | 100% | 99% |

Spielerfehler (Zufallsanteil in der Zugwahl der Spielergruppe, 0 = optimal):

| Fehlerquote | Siegquote |
|--:|--:|
| 0% | 100% |
| 10% | 100% |
| 20% | 100% |
| 30% | 100% |
| 45% | 100% |

### Vorschlag für die Schwierigkeitsstufen

Gewählt nach Ziel-Siegquote einer optimal spielenden Gruppe; ein menschlicher Spieler gewinnt erfahrungsgemäß seltener (siehe Fehlerquote), die Stufen haben also Luft nach oben.

| Stufe | Ziel-Siegquote | Gegner-Leben | Gegner-Angriff | Gemessene Siegquote |
|---|--:|--:|--:|--:|
| Leicht | 90% | ×2.11 | ×2.11 | 83% |
| Normal | 70% | ×2.28 | ×2.28 | 83% |
| Schwer | 45% | ×2.42 | ×2.42 | 49% |
| Meister | 25% | ×2.53 | ×2.53 | 13% |

## 5. Stärkemodell (Grundlage für Gegnerbudgets)

Aus 12000 zufälligen Kämpfen (3–8 Helden gegen 4–18 Soldaten und Stachelia, Gegnerstärke ×1,0–×3,0) per logistischer Regression angepasst. Trefferquote des Modells bei der Vorhersage von Sieg oder Niederlage: **95%**.

**Formel:** `Siegwahrscheinlichkeit = 1 / (1 + e^(−z))` mit `z = c + Σ Heldenwert − Σ (Gegnerkosten × Faktor²)`; Faktor = Gegner-Leben/Angriff-Multiplikator.

Konstante c = -0.98. Werte in Log-Odds; „Punkte“ = Wert geteilt durch die Kosten eines Infanteristen (0.20), also **Infanteristen-Äquivalente**.

| Held | Wert (Log-Odds) | Punkte |
|---|--:|--:|
| Robo | +5.07 | +24.8 |
| Ser Albrecht | +2.31 | +11.3 |
| Takeda | +2.09 | +10.2 |
| Brunhilde Bräu | +1.80 | +8.8 |
| Käpt’n Elisabeth | +1.47 | +7.2 |
| Mira & Brumm | +1.28 | +6.3 |
| Muskelaugust | +1.25 | +6.1 |
| Blauer Hundsfreund | +1.24 | +6.1 |
| Wendy Wolle | +1.20 | +5.9 |
| Kage-Schwestern | +1.19 | +5.8 |
| Claude | +0.90 | +4.4 |
| Meister Lin | +0.76 | +3.7 |
| Stachelia | +0.00 | +0.0 |

| Gegnertyp (Faktor 1) | Kosten (Log-Odds) | Punkte |
|---|--:|--:|
| Infanterie | -0.20 | -1.0 |
| Reiter | -0.46 | -2.3 |
| Bogenschütze | -0.39 | -1.9 |
| Priester | -0.34 | -1.7 |
| Stachelia | -0.00 | -0.0 |

**Benutzung für neue Kapitel:** Kampfgruppe wählen, Σ Heldenwerte ausrechnen, Gegner so zusammenstellen, dass `z` dem Ziel entspricht (z = 0 → 50 %, z = +1 → 73 %, z = +2 → 88 %, z = −1 → 27 %).

## 6. Gegenstände und Ausrüstung

Zufällige 6er-Gruppen gegen 12 Soldaten (Leben/Angriff ×1.5); Grundlinie ohne Gegenstände: **56.0%** Siegquote bei 2500 Kämpfen. „Punkte“ = Gewinn in Infanteristen-Äquivalenten (Stärkemodell aus Abschnitt 5; ein Held ist typisch +3 bis +10 Punkte wert).

### Pakete

| Paket | Δ Sieg | ± | Punkte |
|---|--:|--:|--:|
| Kapitel-1-Ausstattung (2 Heiltränke, 1 Gegengift, 1 Äther, 6 Ausrüstungsstücke) | +19.1 Pp | 1.3 | +4.2 |
| Reicher Rucksack (5 Heiltränke, 3 Gegengifte, 3 Äther, 2 Rauchbomben, 2 Bier) | +20.4 Pp | 1.3 | +4.6 |

### Verbrauchsgüter (jeweils 2 Stück im Rucksack)

| Gegenstand | Δ Sieg | ± | Punkte | Einsätze/Kampf | Wirkung pro Einsatz |
|---|--:|--:|--:|--:|--:|
| Heiltrank | +5.8 Pp | 1.4 | +1.2 | 1.97 | 9.2 Leben |
| Gegengift | +0.9 Pp | 1.4 | +0.2 | 0.99 | 3.0 Leben |
| Äther | +1.4 Pp | 1.4 | +0.3 | 1.98 | 1.0 Statuseffekte |
| Rauchbombe | -0.3 Pp | 1.4 | -0.1 | 2.00 | 3.1 Statuseffekte |
| Bier | +3.5 Pp | 1.4 | +0.7 | 1.97 | 4.4 Leben |

### Ausrüstung (ein Stück an eine zufällige passende Figur der Gruppe)

| Ausrüstung | Platz | Δ Sieg | ± | Punkte |
|---|---|--:|--:|--:|
| Plattenpanzer (+4 Verteidigung, −1 Bewegung) | ruestung | +8.4 Pp | 1.4 | +1.7 |
| Schwere Axt (+4 Angriff, −1 Bewegung) | waffe | +7.0 Pp | 1.4 | +1.4 |
| Eisenschwert (+2 Angriff) | waffe | +6.4 Pp | 1.4 | +1.3 |
| Rubinring (+1 Angriff, +1 Verteidigung) | talisman | +6.2 Pp | 1.4 | +1.3 |
| Kettenhemd (+2 Verteidigung) | ruestung | +4.8 Pp | 1.4 | +1.0 |
| Lederwams (+1 Verteidigung, +4 Leben) | ruestung | +3.8 Pp | 1.4 | +0.8 |
| Fernrohr (+1 Reichweite) | talisman | +3.6 Pp | 1.4 | +0.7 |
| Kristallstab (+3 Angriff) | waffe | +3.0 Pp | 1.4 | +0.6 |
| Heilkraut-Amulett (+8 Leben) | talisman | +2.7 Pp | 1.4 | +0.5 |
| Windstiefel (+1 Bewegung) | talisman | +2.2 Pp | 1.4 | +0.4 |
| Zauberlampe (Fähigkeiten laden 1 Runde schneller) | talisman | +1.0 Pp | 1.4 | +0.2 |
| Magierrobe (+3 Magieresistenz) | ruestung | -0.0 Pp | 1.4 | -0.0 |

## 7. Verteidigen und Spott

Verteidigen: bis zur nächsten eigenen Phase **halber Schaden** (Tanks ×0,4, aufgerundet, mindestens 1), **kein Gegenschlag**, der Zug endet. Die Simulations-KI wählt es nur, wenn ihr bei Bleiben mindestens 35 % der Leben drohen.

### Zufällige Gruppen

| | ohne Verteidigen | mit Verteidigen | Δ |
|---|--:|--:|--:|
| Siegquote | 59.6% | 62.7% | +3.2 Pp ± 1.3 |
| Überlebende Helden | 36% | 41% | +4.3 Pp |
| Ø Runden | 16.0 | 16.2 | |
| Einsätze von Verteidigen pro Kampf | – | 16.49 | |

### Tanks mit Spott (Gruppe: der Tank + 5 Zufallshelden)

Spott „1 Phase“ ist der heutige Stand: Der Spott hat „2 Runden“, wirkt durch die Zählweise aber nur auf die nächste Gegnerphase. „2 Phasen“ würde ihn echt auf zwei Gegnerphasen verlängern.

| Tank | Spott | Siegquote ohne / mit Verteidigen | Δ durch Verteidigen | Tank überlebt ohne / mit |
|---|---|--:|--:|--:|
| Ser Albrecht | aus | 64% / 68% | +4.7 Pp | 59% / 65% |
| Ser Albrecht | 1 Phase (aktuell) | 65% / 69% | +3.7 Pp | 60% / 64% |
| Ser Albrecht | 2 Phasen | 68% / 72% | +4.1 Pp | 62% / 67% |
| Mira & Brumm | aus | 53% / 55% | +1.8 Pp | 21% / 27% |
| Mira & Brumm | 1 Phase (aktuell) | 55% / 60% | +4.3 Pp | 22% / 31% |
| Mira & Brumm | 2 Phasen | 55% / 60% | +4.2 Pp | 22% / 32% |
| Brunhilde Bräu | aus | 55% / 58% | +2.7 Pp | 32% / 38% |
| Brunhilde Bräu | 1 Phase (aktuell) | 60% / 64% | +3.9 Pp | 43% / 49% |
| Brunhilde Bräu | 2 Phasen | 61% / 64% | +2.7 Pp | 42% / 49% |

Zusatzgewinn durch den Spott (jeweils mit Verteidigen), Siegquote in Pp gegenüber „Spott aus“:

| Tank | Spott 1 Phase | Spott 2 Phasen | Zusammenspiel (2 Phasen mit Verteidigen − ohne) |
|---|--:|--:|--:|
| Ser Albrecht | +0.2 | +3.2 | -0.7 |
| Mira & Brumm | +4.8 | +4.9 | +2.4 |
| Brunhilde Bräu | +6.3 | +6.0 | +0.0 |

### Einzelner Ablenker (Meister Lin allein gegen 3 Infanteristen und 1 Bogenschützen, 6 Runden)

| Soldatenangriff | Lin überlebt ohne Verteidigen | mit Verteidigen |
|---|--:|--:|
| 5 (heute) | 31% | 34% |
| 6 | 13% | 16% |
| 7 | 17% | 23% |

## 8. Mission 3: Feuer

Aufstellung wie im Spiel (Albrecht, Mira, Brunhilde, Wendy, Dr. Humbug, Takeda gegen 3 Büttel, 1 Bogenschützen, 1 Reiter und die Zwillinge Oskar und Maja, dazu der Nachschub in Runde 4: 1 Bogenschütze und 1 Büttel). Zahlen: Siegquote / durchschnittlich verlorene Häuser von 4, bei steigender Gegnerstärke (Leben und Angriff ×).

| Variante | ×1.0 | ×1.6 | ×2.2 |
|---|--:|--:|--:|
| Voll (Fasswurf + Löschen von Hand) | 100% / 0.1 | 19% / 0.8 | 0% / 0.7 |
| Ohne Fasswurf (nur Löschen von Hand) | 100% / 0.1 | 12% / 1.7 | 0% / 1.7 |
| Gar nicht löschen | 100% / 4.0 | 33% / 4.0 | 0% / 4.0 |
| Ohne Brunhilde (Lin statt ihr, nur Löschen von Hand) | 100% / 0.0 | 6% / 0.1 | 0% / 1.6 |

## 9. Mission 5: Waisenhaus, Bienenstöcke und Glocke

Aufstellung wie im Spiel (Mira, Albrecht, Wendy, Elisabeth, Kage-Schwestern, Takeda gegen Stachelia mit 40 Leben und 5 Bienenkrieger, dazu 3 Stöcke). Zahlen: Siegquote / Anteil der Kämpfe mit gestochenen Kindern / durchschnittliche Runden, bei steigender Gegnerstärke.

| Variante | ×1.0 | ×1.5 | ×2.0 |
|---|--:|--:|--:|
| Voll (Glocke und Stöcke) | 100% / 27% / 6.4 | 99% / 53% / 11.1 | 31% / 90% / 14.4 |
| Ohne Glocke (kein Hundsfreund) | 100% / 32% / 6.9 | 93% / 48% / 13.4 | 19% / 89% / 14.5 |
| Stöcke ignoriert | 100% / 84% / 8.5 | 51% / 71% / 18.9 | 17% / 91% / 15.9 |
| Weder Glocke noch Stöcke | 94% / 77% / 12.6 | 17% / 69% / 21.5 | 19% / 94% / 16.3 |

## 10. Mission 6: Hafenstadt, Ziel Schiff

Aufstellung wie im Spiel (Hundsfreund, Mira, Elisabeth, Albrecht, Robo, Takeda gegen die Aufstellung der Karte: Büttel, Bogenschützen und Reiter, Wachen auf dem Steg, Kisten-Sperre). Die Auslöser der Mission sind nachgebildet: Wart Runde 3 auf dem Steg (immer), das Beiboot mit Verstärkung Runde 5. Zahlen: Siegquote / durchschnittliche Runden bis zum Schiff, bei steigender Gegnerstärke.

| Variante | ×1.0 | ×1.5 | ×2.0 |
|---|--:|--:|--:|
| Voll (Wart, Beiboot, Breitseite) | 100% / 6.5 | 93% / 13.1 | 1% / 14.4 |
| Ohne Breitseite | 100% / 6.9 | 68% / 15.9 | 0% / 13.8 |

## 11. Warten (wachsam) und Verteidigen

„Warten“ gibt bis zur nächsten eigenen Phase +N Angriff, der nur für den Gegenschlag zählt. Zufällige Gruppen aus 6 Helden gegen 12 Soldaten (Stärke ×1.5). Siegquote, mit Verteidigen aus und an; Einsätze pro Kampf von Warten und Verteidigen.

| Bonus Warten | Verteidigen aus | Verteidigen an | Warten-Einsätze (an) | Verteidigen-Einsätze (an) |
|---|--:|--:|--:|--:|
| +0 Angriff | 58.0% | 62.9% | 21.1 | 16.3 |
| +2 Angriff | 58.1% | 61.0% | 22.6 | 17.3 |
| +3 Angriff | 57.8% | 61.3% | 23.2 | 17.8 |
Die Simulations-KI wartet nur, wenn sie nichts zu tun hat, und nutzt Gegenschläge nicht gezielt. Der Bonus ist hier deshalb neutral (innerhalb des Messrauschens von etwa ±1,5 Pp), er verschiebt das Gleichgewicht nicht. Die Wirkung zeigt sich erst im bewussten Spiel. Für Gegner gilt der Bonus nicht.

## 12. Mission 7: Sandhafen (Wüste, Zwillinge)

Aufstellung der Karte: Elisabeth, Hundsfreund, Mira, Albrecht und je zwei Heiler gegen Oskar (36 Leben), Maja (32 Leben), 3 Büttel, 1 Bogenschützen und 2 Büttel Verstärkung aus der Wüste in Runde 4. Mit den alten Heilern (Wendy und Robo, Robo ist ein Tank) ist die Mission viel leichter: Lumi und Dr. Humbug sind reine Heiler, deshalb liegt die Schwierigkeit mit ihnen höher. Zahlen: Siegquote / durchschnittliche Runden, bei steigender Gegnerstärke.

| Heiler | ×1.0 | ×1.25 | ×1.5 |
|---|--:|--:|--:|
| Mit Lumi und Dr. Humbug | 100% / 12.5 | 86% / 16.3 | 17% / 16.7 |
| Mit Wendy und Robo | 100% / 9.8 | 100% / 12.0 | 90% / 15.1 |

## Grenzen

- Die KI spielt solide, aber nicht perfekt; Fähigkeiten, die kluges Positionieren brauchen (Stabsprung, Wurf, Versteck), werden eher unter- als überschätzt.
- Beide Seiten nutzen dieselbe KI; Spott zwingt auch Spielerfiguren (im Spiel entscheidet der Spieler selbst).
- Höhenunterschiede sind in der Simulation grob (Berg +1,0, Wasser −0,5); das Spiel nutzt ein stetiges Höhenfeld.
- Zufallskarten (12×10, Startzonen links/rechts) statt handgebauter Karten.
