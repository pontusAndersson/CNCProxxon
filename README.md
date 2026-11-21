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
| Stegmotorer | 3x Nema23 23HS8430, 57×57×76 mm, 1.8°, 1.8–1.9 Nm, 3.0 A/fas |
| Drivrutiner | 3x TB6600, 9–42 V, upp till 3.5 A (4.0 A peak) |
| Styrkort | Arduino Uno R3 (ATmega328P) + CNC Shield V3.0 (AZDelivery) |
| Nätaggregat | MW/MAX S-360-24, 24V 15A (360W) |
| Mjukvara (dator) | Arduino IDE (flashning), UGS (Universal G-code Sender) |
| Firmware | GRBL (installerat via Arduino IDE Library Manager) |

**Anmärkning om motorval:** 23HS8430 är egentligen överdimensionerad för en MF70 (Nema17 hade räckt och gett enklare montering), men motorerna ägdes redan innan projektet startade och används därför ändå. Märkdata för den länkade modellen är 3.0 A/fas och cirka 1.8–1.9 Nm. TB6600:s strömtabell går till 3.5 A (4.0 A peak), så inställningen 3.0 A ligger inom drivrutinen. Den nedersta DIP-raden, 3.5 A, ligger över motorns märkström.

**Anmärkning om spänning:** 24V PSU fungerar men ligger i lägsta laget för den här motorn (TB6600 tål 9–42 V). Kan ge minskat vridmoment vid höga hastigheter — eventuell framtida uppgradering till ett 36 V-aggregat om det blir ett problem.

> **Om PSU-uppgradering:** Stegmotorer är specade i **ström** (3.0 A/fas), inte spänning — TB6600 reglerar strömmen elektroniskt oavsett matningsspänning, så motorerna tar ingen skada av högre spänning inom 9–42 V. Rekommenderad uppgradering vid behov: **36 V**, med marginal till taket 42 V. Ett aggregat över 42 V, till exempel 48 V, ligger utanför TB6600 och ska inte användas. Behåll minst samma amperetal (15 A) på det nya PSU:t — strömmen, inte spänningen, avgör hur mycket kraft motorerna kan dra samtidigt. Ingen omkoppling krävs på signalsidan vid PSU-byte.

**Varför inte shieldens inbyggda A4988/DRV8825-socklar?** De klarar max ~2–2,5 A per fas (i praktiken ofta mindre pga värme utan aktiv kylning) — för lite för de här motorerna på 3.0 A/fas. TB6600 har bättre kylkropp och tål kontinuerlig drift vid den strömmen. A4988/DRV8825 hade räckt för lättare Nema17-motorer, men inte för detta bygge.

## Kopplingsschema

**Signalsida (Arduino/Shield → TB6600), per axel — common anode (gemensam +, styr med −):**

| Shield-pin | TB6600-pin |
|---|---|
| 5V (shield, delad buss mellan alla tre TB6600) | PUL+ |
| 5V (shield, samma delade buss) | DIR+ |
| X.STEP / Y.STEP / Z.STEP (unik per axel) | PUL− |
| X.DIR / Y.DIR / Z.DIR (unik per axel) | DIR− |

> **Rättelse:** En tidigare version av denna tabell hade polariteten omvänd. Bekräftat korrekt (mot referensdiagram och TB6600-etikett): plus-sidan (PUL+/DIR+) är den **gemensamma** 5V-bussen, minus-sidan (PUL−/DIR−) är den **unika pulsen** per axel från shieldens STEP/DIR-pinnar.

**Enable (ENA) — lämna okopplad:**

ENA är en offline-ingång. När optokopplaren leder, alltså ENA+ hög och ENA− låg, släpper drivrutinen motorn: axeln går att vrida för hand och pulser ignoreras. Oinkopplad ENA betyder att drivrutinen är aktiverad, och det räcker för det här bygget.

Koppla inte ENA+ till 5V och ENA− till GND. Den kretsen är tänd hela tiden, så motorn står fri.

Vid reset-knappen på CNC Shield V3 sitter två skilda pinnar, EN och GND. EN är D8 och är aktiv låg för shieldens egna A4988/DRV8825. Den signalen är omvänd mot TB6600:s offline-ingång och används inte här.



<img width="1141" height="1475" alt="image" src="https://github.com/user-attachments/assets/15442fc1-7b4a-45ae-b7e2-f1365c101832" />

<img width="1174" height="1601" alt="image" src="https://github.com/user-attachments/assets/fdebbdfe-bbed-4f82-b416-991dadde3765" />

<img width="949" height="800" alt="image" src="https://github.com/user-attachments/assets/b91281bd-e02d-4fa9-86f1-89ced905e5a2" />

`tb6600-orig.jpg` är ett allmänt kopplingsexempel. Nätdelen på den bilden är S-480-24 (24 V, 20 A) och motorn är 23HS7628, inte S-360-24 och 23HS8430 i tabellen ovan.

**Effektsida (PSU → TB6600), delad buss:**

- PSU 24V+ → VCC på alla tre TB6600 (gemensam skruvplint)
- PSU GND → GND på alla tre TB6600 (gemensam skruvplint)
- Rekommenderad kabelarea: minst 1,5mm² på huvudmatning, 0,75–1mm² per TB6600-gren
- Säkring (10–15A) rekommenderad mellan PSU och fördelningsplint

**Motorsida (TB6600 → Motor):**

- TB6600 A+/A-/B+/B- → motorns två spolpar (identifiera med multimeter om ej märkta)
- Koppla aldrig loss motorkabel medan strömmen är på

**Viktigt:** PUL, DIR och ENA går genom optokopplare. Arduino-GND ska inte kopplas till TB6600:s effekt-GND. Nätdelens jord går bara mellan PSU och drivrutinernas GND. Common-anode-kopplingen ovan behöver ingen signaljord till TB6600: strömmen genom optokopplaren går via STEP- eller DIR-pinnen när den dras låg.

## DIP-switchar (TB6600)

Ställ in **alla tre** drivrutiner likadant. Justera **alltid med strömmen av**.

Tabellerna nedan är avskrivna från etiketten på din TB6600 (kloner skiljer sig — lita på lådan).

**Val för detta projekt:** 1/8 microstep + 3.0 A (3.2 A peak).

| Switch | Läge | Betydelse |
|---|---|---|
| SW1 | **OFF** | |
| SW2 | **ON** | 1/8 microstep (1600 puls/varv) |
| SW3 | **OFF** | |
| SW4 | **ON** | |
| SW5 | **OFF** | 3.0 A (3.2 A peak) |
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


## Ändlägesbrytare

**Typ:** Mekaniska mikrobrytare med rullspak/hävarm, 3-stifts SPDT (NO/NC/COM). Standardlösning för hobby-CNC.

**Antal:** 6 st för full täckning (X−/X+/Y−/Y+/Z−/Z+), eller 3 st om bara en ände per axel behövs (räcker för homing).

**Inköpsförslag:**

| Källa | Exempel |
|---|---|
| [3D-shop.se](https://www.3d-shop.se/elektromekanik/brytare/mekanisk-andlagesbrytare) | Mekanisk ändlägesbrytare med 70 cm kabel färdigmonterad, ~14 kr/st |
| [Electrokit](https://www.electrokit.com) | Svensk lagerhållning, brett urval mikrobrytare |
| Amazon.se | Sök "mikrobrytare CNC 3 pin" — t.ex. BOJACK KW4A(S), ofta 10-pack |

**Kabel:** Skärmad 2-ledarkabel rekommenderas (minskar brus från motorkablar), alternativt vanlig CAT5/CAT6-nätverkskabel (tvinnade par, fungerar bra och ofta redan till hands).

**Koppling till shieldens END STOPS-header:**

| Brytarpin | Shield-pin |
|---|---|
| COM | GND |
| NO (Normally Open) | Respektive X−/X+/Y−/Y+/Z−/Z+ |

GRBL:s standardkonfiguration förväntar sig NO-kontakten, som drar signalen till GND vid triggning — ingen extra config behövs.

**Montering:** Placera så att spaken trycks in med några mm marginal innan mekaniskt stopp, så maskinen hinner bromsa.

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
- [ ] Köp in ändlägesbrytare (6 st) + kabel, montera enligt sektionen ovan
- [ ] Koppla in ändlägesbrytare till shieldens END STOPS-header (NO → axel-pinne, COM → GND)
- [ ] Första provkörning med låg hastighet/acceleration, öka stegvis
- [ ] Om drift kvarstår vid höga hastigheter: uppgradera PSU till ~36V (samma eller högre amperetal)

## CNC Shield V3.0

Expansionskort för Arduino Uno R3 (ATmega328P) som bryter ut GRBL:s steg- och riktningssignaler till upp till fyra axlar. GRBL 1.1 i det här repot kör inte på Uno R4. Shielden används **utan** inbyggda A4988/DRV8825 — STEP, DIR och 5V tas ut till externa TB6600-drivrutiner.

### Specifikationer

| | |
|---|---|
| Kompatibilitet | Arduino Uno R3 (ATmega328P). Inte Uno R4 |
| Drivrutinssocklar | 4 (X, Y, Z, A) |
| Tänkta drivrutiner | A4988 / DRV8825 *(används ej här)* |
| Microstepping | Via jumpers på shielden *(irrelevant med TB6600 — ställs på drivrutinen)* |
| Ändlägen | X+/X−, Y+/Y−, Z+/Z− |
| Övrigt | Spindle enable/direction, coolant |
| Motor matning (vid onboard-drivrutiner) | Extern DC 12–36 V |

### Användning i detta projekt

- Arduino Uno + GRBL ger pulser via USB (UGS)
- Shielden ger anslutningspunkter för STEP, DIR och 5V per axel
- Motorström går **inte** via shielden — den matas direkt PSU → TB6600

## Köpa

- [Nema23-stegmotor 23HS8430D8 (Amazon.se)](https://www.amazon.se/23HS8430D8-Stepper-bipoldrivare-ACT-MOTOR/dp/B08PP84ZYT)
- [Nema23 CNC-kit med breakout/controller (Amazon.com)](https://www.amazon.com/Nema23-Stepper-FMD2740C-Breakut-Controller/dp/B07236CFKC)
- [TB6600 / CNC-delar (AliExpress)](https://www.aliexpress.com/item/32843074191.html)

## Resurser

**Mjukvara**

- GRBL: https://github.com/gnea/grbl
- UGS: https://winder.github.io/ugs_website/
- Arduino IDE: https://www.arduino.cc/en/software

**MF70 CNC-konverteringar / inspiration**

- [Aalto Wiki — Proxxon MF70 NC conversion](https://wiki.aalto.fi/display/MEX/Proxxon+MF70+NC+conversion)
- [CNCZone — Vertical mill/lathe project log](https://www.cnczone.com/forums/vertical-mill-lathe-project-log/145312-cnc.html)
- [Brokking — Video 74](http://www.brokking.net/Video_74.html)
- [RCGroups — Proxxon MF70 CNC Mill discussion](https://www.rcgroups.com/forums/showthread.php?1273316-Proxxon-MF70-CNC-Mill-discussion-and-share-ideas)
- [Alexander Impertro — Proxxon MF70 micro mill CNC conversion](https://alexanderimpertro.wordpress.com/2019/04/27/proxxon-mf70-micro-mill-cnc-conversion/)

