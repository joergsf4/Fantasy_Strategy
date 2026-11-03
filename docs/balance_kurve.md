
## 15. Fortschrittskurve (Talentpunkte und Ausrüstungsstufe je Mission)

`python3 tools/balance.py e16`. Die Gruppe der Karte tritt mit den in `data/progression.json` erwarteten **Talentpunkten** (Standardverteilung: Leben, Fähigkeit 1, Angriff, Fähigkeit 2 der Reihe nach) und der erwarteten **Ausrüstungsstufe** an (je Platz das beste Stück bis zu dieser Stufe) gegen die Gegner der Karte, multipliziert mit dem Faktor in der Kopfzeile. Zahl = Siegquote. Zielquote steht in der Tabelle; der **Faktor, bei dem die Zielquote erreicht ist**, zeigt, wie viel Luft die Mission nach oben hat.

| Mission | Punkte | Ausr. | Ziel | ×1.0 | ×1.25 | ×1.5 | ×1.75 | ×2.0 | ×2.5 | Faktor für Ziel |
|---|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| Mission 1 | 0 | 1.0 | 97% | 100% | 100% | 100% | 99% | 91% | 8% | ≈ 1.75–2.0 |
| Mission 3 | 0 | 1.0 | 95% | 100% | 100% | 93% | 9% | 0% | 0% | ≈ 1.25–1.5 |
| Mission 5 | 1 | 1.5 | 92% | 100% | 100% | 100% | 84% | 21% | 0% | ≈ 1.5–1.75 |
| Mission 6 | 1 | 1.5 | 92% | 100% | 100% | 84% | 11% | 0% | 0% | ≈ 1.25–1.5 |
| Mission 7 | 2 | 2.0 | 92% | 100% | 100% | 94% | 36% | 0% | 0% | ≈ 1.5–1.75 |
| Mission 8 | 2 | 2.0 | 90% | 92% | 95% | 60% | 24% | 3% | 0% | ≈ 1.25–1.5 |
| Mission 12 | 3 | 3.0 | 85% | 100% | 100% | 100% | 97% | 80% | 2% | ≈ 1.75–2.0 |
