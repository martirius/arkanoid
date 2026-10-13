# Piano di miglioramento architetturale

## Obiettivo

Rendere il gameplay più affidabile e semplice da evolvere senza riscrivere il
progetto e senza introdurre framework di stato non necessari. Ogni fase deve
mantenere il gioco eseguibile, avere test proporzionati al rischio e produrre un
commit separato.

## Architettura di riferimento

```text
Arkanoid
├── GameSession          punteggio, vite e livello corrente
├── RoundController      stato e transizioni del round
│   ├── BrickGrid        stato del campo
│   ├── Ball
│   ├── Starship
│   └── PowerUp
├── InputController      tastiera, joystick e pulsante
└── GameAudio            riproduzione e ciclo di vita dell'audio
```

I componenti Flame restano responsabili di rendering e interazioni locali. Lo
stato persistente del round non deve essere dedotto dalla presenza dei
componenti nell'albero di gioco.

## Fasi

### 1. Test di caratterizzazione

- coprire perdita della vita e ripristino del round;
- verificare che i brick già distrutti non vengano ricreati;
- coprire la distruzione di più brick nello stesso frame;
- coprire le transizioni `READY`, gioco attivo e game over;
- non cambiare il comportamento del gioco in questa fase.

### 2. Gestione event-driven dei brick

- introdurre un proprietario unico dello stato della griglia;
- notificare direttamente la distruzione indicando riga e colonna;
- aggiornare matrice, punteggio e completamento del livello in modo atomico;
- eliminare la scansione dei figli da `BaseLevel.update`.

### 3. Stato esplicito del round

- introdurre `RoundPhase` con gli stati `intro`, `ready`, `playing`,
  `lifeLost`, `escaping`, `completed` e `gameOver`;
- sostituire i booleani che descrivono lo stato del round;
- usare timer legati al ciclo di vita dei componenti per evitare callback di
  livelli già rimossi.

### 4. Centralizzazione dell'input

- tradurre tastiera, joystick e pulsante in azioni semantiche;
- gestire movimento e azione da un unico punto;
- eseguire l'azione una sola volta alla pressione;
- decidere nel controller se l'azione avvia la pallina, la libera o spara.

### 5. Definizioni immutabili dei livelli

- introdurre `LevelDefinition` e `BrickSpec`;
- mantenere inizialmente le definizioni in Dart;
- validare numero di righe e colonne;
- sostituire le classi `Level1`-`Level5` e lo `switch` con un catalogo ordinato.

### 6. Viewport a risoluzione logica fissa

- usare il campo originale `224 × 240` come spazio logico del mondo;
- lasciare HUD e comandi nello spazio dello schermo;
- eliminare progressivamente lo scaling manuale dalle entità;
- verificare layout e controlli su differenti rapporti d'aspetto.

### 7. Isolamento della fisica della pallina

- estrarre soltanto il calcolo puro degli impatti in un resolver testabile;
- lasciare rendering e integrazione Flame nel componente `Ball`;
- procedere solo con una copertura sufficiente delle collisioni per evitare
  regressioni.

## Ordine e criteri di completamento

Ogni fase è completa quando:

1. i test mirati passano;
2. l'intera suite Flutter passa;
3. `dart analyze` non presenta nuovi problemi;
4. la build Android debug riesce, quando la fase modifica codice di runtime;
5. viene creato un commit contenente soltanto i file della fase.

Il level editor web rimane fuori dalle prime fasi. Verrà adattato alle nuove
definizioni dei livelli durante la fase 5.
