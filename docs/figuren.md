# Figuren – Kampfsystem-Entwurf

Schreib unter jede Figur, was du dir vorstellst. Die Werte sind der **aktuelle Prototyp-Stand** und nur Platzhalter, ändere sie ruhig.

**Typ** (Beispiele): Nahkämpfer, Panzer, Fernkämpfer, Magier, Heiler/Unterstützer, Flieger, Reiter, Assassine …  
**Spezial** (Beispiele): aktive Fähigkeit mit Abklingzeit oder Ladung, passive Eigenschaft, Aura für Nachbarn, Kombo mit einer bestimmten Figur, Statuseffekt (Gift, Betäubung, Brennen …), Spezialangriff mit Fläche/Linie.

**Derzeit im Spiel:** Zugbasiert auf Raster, Angriff ⇒ Gegenschlag falls in dessen Reichweite, Geländedeckung (Wald +1, Berg +2, Dorf +1, Burg +2), Wasser unpassierbar (Flieger ausgenommen). Schaden = Angriff − Verteidigung − Deckung (mindestens 1).

---

## Helden

### Mira & Brumm
*Mädchen mit dem Bären als Freund*  
`maedchen_baer` · Chibi: `game/assets/tokens/maedchen_baer.png`  
Aktuell: HP 22 · Angriff 7 · Verteidigung 3 · Bewegung 4 · Reichweite 1

**Typ:** 
Nahkampf
**Spezialattacke / Fähigkeit:** 
Bärenpranke
Angriff der dafür sorgt, dass gegner sie angreifen.
**Sonstiges (Rolle, Story, Kombos):** 
Tank mit viel leben
---

### Ser Albrecht
*Gealterter Ritter*  
`ritter` · Chibi: `game/assets/tokens/ritter.png`  
Aktuell: HP 30 · Angriff 8 · Verteidigung 6 · Bewegung 3 · Reichweite 1

**Typ:** 
Nahkampf
**Spezialattacke / Fähigkeit:** 
1. Schlachtruf bufft die Verbündeten in direkter Umgebung
2. Verspotten > gegner muss ihn angreifen
**Sonstiges (Rolle, Story, Kombos):** 
Tank
---

### Takeda
*Samurai*  
`samurai` · Chibi: `game/assets/tokens/samurai.png`  
Aktuell: HP 24 · Angriff 9 · Verteidigung 4 · Bewegung 4 · Reichweite 1

**Typ:** 
Nahkampf
**Spezialattacke / Fähigkeit:** 
Tpodeswirbel > Viel Schaden
**Sonstiges (Rolle, Story, Kombos):** 

---

### Meister Lin
*Kung-Fu-Kämpfer mit Stab*  
`kungfu` · Chibi: `game/assets/tokens/kungfu.png`  
Aktuell: HP 22 · Angriff 7 · Verteidigung 3 · Bewegung 4 · Reichweite 1

**Typ:** 
Nahkampf
**Spezialattacke / Fähigkeit:** 
Stabsprung > er Springt über den Gegner auf das Feld dirkt dahinter
**Sonstiges (Rolle, Story, Kombos):** 

---

### Die Kage-Schwestern
*Ninja-Schwestern (gelb und rot, zählen als eine Figur)*  
`ninjas` · Chibi: `game/assets/tokens/ninjas.png`  
Aktuell: HP 18 · Angriff 8 · Verteidigung 2 · Bewegung 6 · Reichweite 1

**Typ:** 
Fernkampf und Nahkampf
**Spezialattacke / Fähigkeit:** 
Versteck > können nicht angegriffen werden.
**Sonstiges (Rolle, Story, Kombos):** 
Schaden
---

### Käpt’n Elisabeth
*Piratenmädchen mit Fernrohr, schießt mit Kanonen*  
`elisabeth` · Chibi: `game/assets/tokens/elisabeth.png`  
Aktuell: HP 17 · Angriff 7 · Verteidigung 2 · Bewegung 3 · Reichweite 2

**Typ:** 
Fernkampf
**Spezialattacke / Fähigkeit:** 
Kanone > Elisabeth feuert eine große Kanone auf Gegner. Am gegner angrenzende Feinde bekommen 50% des Schadens ab.
**Sonstiges (Rolle, Story, Kombos):** 
Schaden
---

### Muskelaugust
*Barocker Kurfürst und König mit absurden Muskeln, Nahkampf ohne Waffen*  
`museklaugust` · Chibi: `game/assets/tokens/museklaugust.png`  
Aktuell: HP 34 · Angriff 10 · Verteidigung 2 · Bewegung 3 · Reichweite 1

**Typ:** 
Nahkampf
**Spezialattacke / Fähigkeit:** 
Gegner werfen > Gegner werden 4 Felder weit geworfen in eine zufällige Richtung und sind dann eine Runde benommen
**Sonstiges (Rolle, Story, Kombos):** 
Schade
---

### Robo
*Roboter-Kämpfer*  
`robo` · Chibi: `game/assets/tokens/robo.png`  
Aktuell: HP 32 · Angriff 8 · Verteidigung 7 · Bewegung 3 · Reichweite 1

**Typ:** 
Fernkampf
**Spezialattacke / Fähigkeit:** 
1. roter Laser > Fernangriff mit großem Schaden.
2. grüner Laser > heilt ein Ziel
**Sonstiges (Rolle, Story, Kombos):** 
Schaden und Heiler
---

### Blauer Hundsfreund
*Anthropomorpher Hund (Blue Heeler), kämpft mit je einem schweren Knochen*  
`hund` · Chibi: `game/assets/tokens/hund.png`  
Aktuell: HP 26 · Angriff 8 · Verteidigung 4 · Bewegung 4 · Reichweite 1

**Typ:** 
Nahkampf(fern nur mit Spezialattacke)
**Spezialattacke / Fähigkeit:** 
Knochenwurf > Trifft gegner, die max 2 Felder entfernt sind mit eine Serie an Knochen.
**Sonstiges (Rolle, Story, Kombos):** 
Schaden
---

### Wendy Wolle
*Anthropomorphes Schaf, Heilerin*  
`wendy` · Chibi: `game/assets/tokens/wendy.png`  
Aktuell: HP 18 · Angriff 4 · Verteidigung 2 · Bewegung 3 · Reichweite 2, heilt 8

**Typ:** 
Fernkampf
**Spezialattacke / Fähigkeit:** 
Heilung
Gruppenheilung(fläche)
**Sonstiges (Rolle, Story, Kombos):** 
Heiler
---

### Claude
*Flaschengeist, kämpft als Magier*  
`claude` · Chibi: `game/assets/tokens/claude.png`  
Aktuell: HP 16 · Angriff 9 · Verteidigung 1 · Bewegung 3 · Reichweite 2

**Typ:** 
Fernkampf
**Spezialattacke / Fähigkeit:** 
Polymporph > nimmt standardeinheiten aus dem Spiel für 3 Runden.
**Sonstiges (Rolle, Story, Kombos):** 

---

### Stachelia
*Bienenmädchen (gruselig), fliegt, kann vergiften*  
`bienenmaedchen` · Chibi: `game/assets/tokens/bienenmaedchen.png`  
Aktuell: HP 16 · Angriff 6 · Verteidigung 2 · Bewegung 5 · Reichweite 1, fliegt

**Typ:** 
Fernkampf
**Spezialattacke / Fähigkeit:** 
Giftstachel > vergiftet gegner für 3 Runden(schlimmer dot muss gegengeheilt werden)
**Sonstiges (Rolle, Story, Kombos):** 
Böse, General vom Boss
Schaden
---

### Brunhilde Bräu
*Bodybuilderin, braut Bier, trägt und wirft Fässer*  
`braumeisterin` · Chibi: `game/assets/tokens/braumeisterin.png`  
Aktuell: HP 28 · Angriff 9 · Verteidigung 3 · Bewegung 3 · Reichweite 1

**Typ:** 
Tank
**Spezialattacke / Fähigkeit:** 
Fasswurf > Macht gegner wütend und zwing sie zum Angriff auf Brunhilde
**Sonstiges (Rolle, Story, Kombos):** 
Tank
---

## Weitere Figuren

### Kampfsport-Trainingsattrappe
*Der persönliche Trainingspartner des Regenten, in Mission 6 („Möwenbucht“) als **Gegenspieler** ausgeschickt, um die Überfahrt zu verhindern. Bilder: Porträt und Karten-Figur fertig.*
`dummy` · Chibi: `game/assets/tokens/dummy.png`
Aktuell (Platzhalter): HP 34 · Angriff 8 · Verteidigung 4 · Bewegung 3 · Reichweite 1 · Boss

**Typ:** Nahkampf, zäher Brocken aus Eichenholz („Ich bin nicht aus Holz, ich bin aus … Eichenholz!“)

**Spezialattacke / Fähigkeit:** **Wirbel**: trifft alle 8 Nachbarfelder (×1,5), danach erschöpft (−2 Verteidigung), Abklingzeit 3. Die Gegner-KI setzt ihn ein, wenn mindestens 2 Helden daneben stehen.

**Sonstiges:** Greift in Mission 6 in Runde 4 von hinten ein (Stadttor). Flieht wütend statt zu sterben und kehrt im Finale zurück.

---

### Bösewicht (Regent Morgrim)
*Stereotyper Bösewicht. Bild fehlt noch.*

**Typ:** 

**Spezialattacke / Fähigkeit:** 

---

## Ikonische Gegenspieler (Generäle des Regenten)

Bilder fertig (Porträt, lachend, wütend, Karten-Figur). Wart, Oskar und Maja sind im Spiel (Werte und Fähigkeiten sind meine Platzhalter-Vorschläge). **Xiùlán ist im Spiel** (Mission 4 „Das Teehaus am Pass“, Gebiss-Wurf als Fernangriff mit Abklingzeit 3: Reichweite 2–4, ×1,4; HP 38, ATK 8, DEF 3).

### Wart
*Anthropomorphes Wildschwein, fies bis an die Zähne bewaffnet, Raketenwerfer*  
`wart`

**Typ:** Fernkampf-Schaden (Boss), HP 42 · ATK 10 · DEF 4 · BEW 3 · Reichweite 1–2 (Platzhalterwerte)

**Spezialattacke / Fähigkeit:** Raketenwerfer: Reichweite 2–4, ×1,6, Gegner neben dem Ziel erhalten 50 % (Abklingzeit 3). **Im Spiel:** Mission 2 „Der Hohlweg“

**Sonstiges (Rolle, Story, Kombos):** Trägt Gold und eine Rauchbombe. Wertet der Vorschlag nach dem ersten Spieltest nach.

---

### Xiùlán
*Asiatische Oma, kämpft im Mantis-Style-Kung-Fu, kann ihr Gebiss (dritte Zähne) werfen*  
`xiulan`

**Typ:** 

**Spezialattacke / Fähigkeit:** 

**Sonstiges (Rolle, Story, Kombos):** 

---

### Oskar
*General, jung, hübsch, blond, kann seine Truppen buffen*  
`oskar`

**Typ:** Unterstützer-General (Boss), HP 34 · ATK 7 · DEF 4 · RES 3 · BEW 4 (Platzhalterwerte)

**Spezialattacke / Fähigkeit:** Feldherrenbefehl: Truppen im Umkreis 3 erhalten +3 Angriff, +2 Verteidigung für 2 Runden (Abklingzeit 4). **Im Spiel:** Mission 3 „Mühlbach in Flammen“

**Sonstiges (Rolle, Story, Kombos):** Zwillingsbruder von Maja. Setzt den Befehl ein, sobald mindestens 2 Verbündete in der Nähe sind.

---

### Maja
*Zwillingsschwester des Generals, schüchtert Gegner ein, sehr hübsch und fies*  
`maja`

**Typ:** Schadensausteiler (Boss), HP 30 · ATK 8 · DEF 3 · RES 5 · BEW 4 · Reichweite 1–2 (Platzhalterwerte)

**Spezialattacke / Fähigkeit:** Eisiger Blick: Helden im Umkreis 2 sind 2 Runden eingeschüchtert (−3 Angriff, −1 Verteidigung), Abklingzeit 3. **Im Spiel:** Mission 3

**Sonstiges (Rolle, Story, Kombos):** Zwillingsschwester von Oskar. Wird sie besiegt, reagiert er wütend (und umgekehrt).

---

## Generische Soldaten (Gegner)

### Infanterie
*Schwert und Rundschild*  
`soldat_infanterie`  
Aktuell: HP 14 · Angriff 5 · Verteidigung 2 · Bewegung 3 · Reichweite 1

**Typ:** 

**Spezial (falls gewünscht):** 

---

### Berittener Soldat
*Lanze, gepanzertes Pferd*  
`soldat_beritten`  
Aktuell: HP 18 · Angriff 6 · Verteidigung 2 · Bewegung 5 · Reichweite 1

**Typ:** 

**Spezial (falls gewünscht):** 

---

### Bogenschütze
*Langbogen*  
`soldat_bogenschuetze`  
Aktuell: *noch keine Werte*

**Typ:** 

**Spezial (falls gewünscht):** 

---

### Priester
*Stab mit leuchtender Kugel*  
`soldat_priester`  
Aktuell: *noch keine Werte*

**Typ:** 

**Spezial (falls gewünscht):** 

---

## Allgemeine Fragen zum Kampfsystem

Falls du dazu schon Ideen hast, schreib sie hier hin:

- Waffen-/Typ-Dreieck (Schere-Stein-Papier) ja oder nein?
- Gegenschlag immer, oder nur bei passender Reichweite? (Fernkämpfer im Nahkampf?)
- Doppelangriff bei hoher Geschwindigkeit (wie bei Fire Emblem)?
- Erfahrung und Level-ups, oder feste Werte pro Kapitel?
- Haltbarkeit der Waffen, oder unbegrenzt?
- Fähigkeiten: Ladung/Abklingzeit, Ausdauer-Punkte oder frei einsetzbar?
- Sterben Figuren dauerhaft (Permadeath)?
- Sammelmechanik: wie kommen neue Figuren dazu (Story, Dorf besuchen, Gefangene, Shop)?
- Kombos/Unterstützung: Bonus, wenn bestimmte Figuren nebeneinander stehen?

**Deine Notizen:**

