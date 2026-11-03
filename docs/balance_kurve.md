
## 15. Fortschrittskurve (Heldenstufe und Ausrüstungsstufe je Mission)

`python3 tools/balance.py e16`. Die Gruppe der Karte tritt mit der in `data/progression.json` erwarteten **Heldenstufe** und **Ausrüstungsstufe** an (je Platz das beste Stück bis zu dieser Stufe) gegen die Gegner der Karte, multipliziert mit dem Faktor in der Kopfzeile. Zahl = Siegquote. Zielquote steht in der Tabelle; der **Faktor, bei dem die Zielquote erreicht ist**, zeigt, wie viel Luft die Mission nach oben hat.

| Mission | Stufe | Ausr. | Ziel | ×1.0 | ×1.25 | ×1.5 | ×1.75 | ×2.0 | ×2.5 | Faktor für Ziel |
|---|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| Mission 1 | 1 | 1.0 | 97% | 100% | 100% | 100% | 99% | 91% | 8% | ≈ 1.75–2.0 |
| Mission 3 | 2 | 1.0 | 95% | 100% | 100% | 100% | 98% | 53% | 0% | ≈ 1.75–2.0 |
| Mission 5 | 2 | 1.5 | 92% | 100% | 100% | 100% | 100% | 100% | 58% | ≈ 2.0–2.5 |
| Mission 6 | 3 | 1.5 | 92% | 100% | 100% | 100% | 100% | 100% | 52% | ≈ 2.0–2.5 |
| Mission 7 | 3 | 2.0 | 92% | 100% | 100% | 100% | 100% | 99% | 16% | ≈ 2.0–2.5 |
| Mission 8 | 3 | 2.0 | 90% | 92% | 96% | 94% | 68% | 38% | 9% | ≈ 1.5–1.75 |
| Mission 12 | 4 | 3.0 | 85% | 100% | 100% | 100% | 100% | 100% | 100% | &gt; 2,0 |
