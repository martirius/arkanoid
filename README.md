# Project Arkanoid

Remake in Flutter e Flame di **Arkanoid**, ispirato principalmente alla versione
arcade Taito del 1986. Il progetto è giocabile, ma resta in sviluppo: l'obiettivo
è riprodurre progressivamente regole, controlli, grafica e timing dell'arcade
senza emularne direttamente il codice.

## Stato del progetto

Attualmente sono disponibili:

- i 32 round arcade con griglia da 13 colonne, seguiti dal round 33 con Doh;
- intro, menu principale, selezione Easy/Hard, HUD, pausa, continue e finale;
- sospensione temporanea della partita e ripresa dal menu principale;
- tre vite iniziali, crediti, vite extra a punteggio e capsula Player;
- tutti i power-up: Slow, Catch, Laser, Extend, Disruption, Break e Player;
- quattro tipi di alieni, porte animate e timing Easy/Hard ricavati dalla ROM
  arcade;
- fisica della pallina con collisioni continue per evitare attraversamenti e
  rimbalzi errati ad alta velocità;
- controlli touch, mouse e tastiera;
- layout portrait e landscape nel rispetto della safe area del dispositivo.

La sospensione conserva lo stato soltanto mentre l'applicazione rimane aperta:
non è ancora presente un salvataggio persistente su disco.

## Controlli

### Desktop

- movimento del mouse: sposta la Vaus;
- clic sinistro: lancia la pallina, rilascia Catch o spara i laser;
- frecce sinistra/destra oppure `A`/`D`: movimento alternativo;
- `Spazio` o `Invio`: azione;
- `Esc` o `P`: pausa.

### Mobile

- trascina il dito nel riquadro di movimento per controllare la Vaus;
- usa il pulsante Fire per le azioni;
- usa il pulsante pausa per riprendere, sospendere o terminare la partita.

## Avvio

È richiesto un SDK Flutter compatibile con Dart 3.

```bash
flutter pub get
flutter run
```

Per scegliere esplicitamente una piattaforma:

```bash
flutter devices
flutter run -d <device-id>
```

Non è necessario eseguire `build_runner`.

## Verifica

```bash
dart analyze
flutter test
```

La suite copre regole dei round, collisioni, velocità e traiettorie della
pallina, power-up, alieni, Doh, audio, input, viewport e ciclo dei menu.

## Struttura principale

- `lib/main.dart`: ciclo applicativo, menu, pausa, sospensione e progressione;
- `lib/components/`: entità e sequenze Flame;
- `lib/components/levels/`: definizioni e runtime dei round;
- `lib/physics/`: movimento e risoluzione continua delle collisioni;
- `lib/enemy_director.dart`: slot, porte e generazione degli alieni;
- `lib/power_up_director.dart`: regole di rilascio delle capsule;
- `lib/level_editor/`: editor visuale dei livelli;
- `test/`: test unitari e widget.

Le decisioni di compatibilità sono documentate in
[`docs/arcade-behavior-decisions.md`](docs/arcade-behavior-decisions.md). Il
piano storico di confronto con la versione MSX è disponibile in
[`docs/msx-gameplay-parity-plan.md`](docs/msx-gameplay-parity-plan.md).

## Editor dei livelli

L'editor è una utility web ancora essenziale. Può essere avviato con:

```bash
flutter run -d chrome -t lib/level_editor/level_editor.dart
```

Permette di scegliere mattoni, power-up, numero del round e sfondo, quindi
generare il codice Dart della definizione. Il file prodotto deve essere
integrato manualmente nel catalogo dei livelli.

## Lavori ancora aperti

- persistenza della partita sospesa dopo la chiusura dell'app;
- ulteriore confronto visivo e frame-by-frame di animazioni e timing arcade;
- rifinitura dell'editor dei livelli;
- verifica sistematica di build e comportamento su tutte le piattaforme
  Flutter configurate.

## Asset e riferimenti

Parte degli sprite e degli effetti sonori deriva dal gioco originale ed è stata
reperita tramite
[The Spriters Resource](https://www.spriters-resource.com/arcade/arkanoid/).
Il progetto è destinato allo studio; prima di distribuire asset originali è
necessario verificarne separatamente diritti e licenze.
