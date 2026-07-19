<img width="774" height="465" alt="image" src="https://github.com/user-attachments/assets/33f2d1c7-649f-435e-a1fe-574c44c5eee0" />

# Proxxon MF70 CNC-konvertering

Dokumentation av min ombyggnad av en Proxxon MF70 till en USB-styrd 3-axlig CNC-fräs, driven via Arduino + GRBL.

## Status

- [x] Mekanisk montering av axelkonsoler (X/Y/Z)
- [x] Elektronik vald och delvis inkopplad
- [x] GRBL flashat till Arduino, USB-anslutning verifierad
- [ ] TB6600-drivrutiner slutgiltigt inkopplade och strömtestade
- [ ] Steg/mm beräknat och konfigurerat i GRBL
- [ ] Första testfräsning

## Bakgrund / historik

Maskinen kördes ursprungligen med ett TB6560-baserat USB-styrkort (Mach3), men gav återkommande problem med tappade steg och drift över tid. Detta spårades till en kombination av:

- Ojämn USB-pulsgenerering i TB6560-kortet
- Undermålig strömreglering / överhettning i TB6560-chippet
- Eventuell mekanisk friktion (under utredning)

**Beslut:** Byta ut hela styrkedjan mot en mer robust lösning: Arduino Uno + GRBL-firmware + separata TB6600-drivrutiner, styrt via USB med UGS som g-kodsändare.

## Hårdvara

| Komponent | Detaljer |
|---|---|
| Maskin | Proxxon MF70, CNC-konverterad med axelkonsoler (X/Y/Z) |
| Stegmotorer | 3x Nema23 57x57x76mm, 1.8° step, 1.8Nm, 4A/fas |
| Drivrutiner | 3x TB6600, 4A, 9–42V, 2/4-fas |
| Styrkort | Arduino Uno + CNC Shield V3.0 (AZDelivery) |
| Nätaggregat | MW/MAX S-360-24, 24V 15A (360W) |
| Mjukvara (dator) | Arduino IDE (flashning), UGS (Universal G-code Sender) |
| Firmware | GRBL (installerat via Arduino IDE Library Manager) |

**Anmärkning om motorval:** Nema23 är egentligen överdimensionerat för en MF70 (Nema17 hade räckt och gett enklare montering), men motorerna ägdes redan innan projektet startade och används därför ändå. TB6600 klarar strömmen (4A/fas) utan problem.

**Anmärkning om spänning:** 24V PSU fungerar men ligger i lägsta laget för Nema23 (TB6600 tål upp till 42V). Kan ge minskat vridmoment vid höga hastigheter — eventuell framtida uppgradering till 36–48V PSU om det blir ett problem.

## Kopplingsschema

**Signalsida (Arduino/Shield → TB6600), per axel — common cathode (gemensam −, styr med +):**

| Shield-pin | TB6600-pin |
|---|---|
| X.STEP / Y.STEP / Z.STEP | PUL+ |
| X.DIR / Y.DIR / Z.DIR | DIR+ |
| GND (shield, delad mellan alla TB6600) | PUL− |
| GND (shield, samma) | DIR− |



<img width="1141" height="1475" alt="image" src="https://github.com/user-attachments/assets/15442fc1-7b4a-45ae-b7e2-f1365c101832" />

<img width="1174" height="1601" alt="image" src="https://github.com/user-attachments/assets/fdebbdfe-bbed-4f82-b416-991dadde3765" />




**Effektsida (PSU → TB6600), delad buss:**

- PSU 24V+ → VCC på alla tre TB6600 (gemensam skruvplint)
- PSU GND → GND på alla tre TB6600 (gemensam skruvplint)
- Rekommenderad kabelarea: minst 1,5mm² på huvudmatning, 0,75–1mm² per TB6600-gren
- Säkring (10–15A) rekommenderad mellan PSU och fördelningsplint

**Motorsida (TB6600 → Motor):**

- TB6600 A+/A-/B+/B- → motorns två spolpar (identifiera med multimeter om ej märkta)
- Koppla aldrig loss motorkabel medan strömmen är på

**Viktigt:** Signal-GND (Arduino ↔ TB6600) och effekt-GND (PSU ↔ TB6600) hålls som separata kretsar för att undvika brus, trots att båda till slut delar samma nollpunkt i systemet.

## DIP-switchar (TB6600)

Ställ in **alla tre** drivrutiner likadant. Justera **alltid med strömmen av**.

Tabellerna nedan är avskrivna från etiketten på din TB6600 (kloner skiljer sig — lita på lådan).

**Val för detta projekt:** 1/8 microstep + 3.0 A (3.2 A peak).

| Switch | Läge | Betydelse |
|---|---|---|
| SW1 | **OFF** | |
| SW2 | **ON** | 1/8 microstep (1600 puls/varv) |
| SW3 | **OFF** | |
| SW4 | **OFF** | |
| SW5 | **ON** | 3.0 A (3.2 A peak) |
| SW6 | **OFF** | |

Kort: `OFF ON OFF ON OFF OFF`

### Referenstabeller (från din TB6600-etikett)

**Microstep (SW1–SW3):**

| Microstep | Puls/varv | SW1 | SW2 | SW3 |
|---|---|---|---|---|
| NC | — | ON | ON | ON |
| 1 (full) | 200 | OFF | ON | ON |
| 2/A | 400 | ON | OFF | ON |
| 2/B | 400 | OFF | OFF | ON |
| 4 | 800 | ON | ON | OFF |
| **8** | **1600** | **OFF** | **ON** | **OFF** |
| 16 | 3200 | ON | OFF | OFF |
| 32 | 6400 | OFF | OFF | OFF |

**Ström (SW4–SW6):**

| Ström | Peak | SW4 | SW5 | SW6 |
|---|---|---|---|---|
| 0.5 A | 0.7 A | ON | ON | ON |
| 1.0 A | 1.2 A | OFF | ON | ON |
| 1.5 A | 1.7 A | ON | OFF | ON |
| 2.0 A | 2.2 A | OFF | OFF | ON |
| 2.5 A | 2.7 A | ON | ON | OFF |
| 2.8 A | 2.9 A | OFF | ON | OFF |
| **3.0 A** | **3.2 A** | **ON** | **OFF** | **OFF** |
| 3.5 A | 4.0 A | OFF | OFF | OFF |

Vald microstepping måste matcha GRBL `$100/$101/$102` (steg/mm).

<img width="3024" height="4032" alt="IMG_1526" src="https://github.com/user-attachments/assets/854e0fff-7d5d-4755-b6cf-f0700efc435e" />


## Mjukvaruinstallation

1. Installera [Arduino IDE](https://www.arduino.cc/en/software)
2. I Arduino IDE: **Sketch → Include Library → Manage Libraries**, sök på "grbl", installera
3. **File → Examples → grbl → grblUpload**, välj rätt board (Uno) och port, klicka Upload
   - Varning om minnesanvändning (~92% flash, ~79% RAM) är normalt för GRBL på Uno och kan ignoreras
4. Installera [UGS (Universal G-code Sender)](https://winder.github.io/ugs_website/) på styrdatorn
5. Anslut Arduino via USB, öppna UGS, välj rätt port, baudrate **115200**, klicka Connect
   - Verifierat: GRBL svarar med välkomstmeddelande `Grbl x.xx ['$' for help]`

## Kända problem / felsökning

**Tappade steg / drift över tid (ursprungsproblem med TB6560):**
Möjliga orsaker i prioritetsordning: mekanisk bindning, understäld ström på drivrutin, för hög acceleration i mjukvarukonfig, elektriskt brus i kablage, överhettning i drivsteg, felmatchad microstepping mellan drivrutin och mjukvarukonfig. Förväntas minska rejält med TB6600 + GRBL jämfört med tidigare TB6560/Mach3-kombo.

## Återstående arbete

- [ ] Ställ in DIP-switchar på varje TB6600 enligt sektionen ovan (`OFF ON OFF ON OFF OFF`)
- [ ] Beräkna och sätt `$100/$101/$102` (steg/mm) i GRBL utifrån kulskruvens stigning och 1/8 microstep (1600 puls/varv)
- [ ] Koppla in ändlägesbrytare (shieldens X+/X-/Y+/Y-/Z+/Z- mot GND)
- [ ] Första provkörning med låg hastighet/acceleration, öka stegvis
- [ ] Om drift kvarstår: överväg 36–48V PSU-uppgradering för mer marginal på Nema23

## CNC Shield V3.0

Expansionskort för Arduino Uno R3/R4 som bryter ut GRBL:s steg-/riktningssignaler till upp till fyra axlar. I detta projekt används shielden **utan** inbyggda A4988/DRV8825 — istället tas STEP/DIR/GND ut till externa TB6600-drivrutiner.

### Specifikationer

| | |
|---|---|
| Kompatibilitet | Arduino Uno R3/R4 |
| Drivrutinssocklar | 4 (X, Y, Z, A) |
| Tänkta drivrutiner | A4988 / DRV8825 *(används ej här)* |
| Microstepping | Via jumpers på shielden *(irrelevant med TB6600 — ställs på drivrutinen)* |
| Ändlägen | X+/X−, Y+/Y−, Z+/Z− |
| Övrigt | Spindle enable/direction, coolant |
| Motor matning (vid onboard-drivrutiner) | Extern DC 12–36 V |

### Användning i detta projekt

- Arduino Uno + GRBL ger pulser via USB (UGS)
- Shielden ger praktiska anslutningspunkter för STEP, DIR och GND per axel
- Motorström går **inte** via shielden — den matas direkt PSU → TB6600

## Resurser

- GRBL: https://github.com/gnea/grbl
- UGS: https://winder.github.io/ugs_website/
- Arduino IDE: https://www.arduino.cc/en/software

