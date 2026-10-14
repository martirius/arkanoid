# Piano di parità gameplay con Arkanoid MSX

## Obiettivo e fonte

Questo piano confronta il comportamento attuale del progetto con il
disassembly annotato di Arkanoid per MSX, fissato al commit
[`20f5b7b`](https://github.com/mcolom/arkanoid_msx_disasm/tree/20f5b7ba8e3d4ee04e0cfc051a3dfd98dbed233e).
L'obiettivo non è copiare l'implementazione Z80 né riprodurre i limiti hardware,
ma portare nel gioco le regole osservabili e mantenerle testabili.

Il progetto usa grafica e geometria derivate dalla versione arcade. Le
differenze specifiche del port MSX, soprattutto formato dei livelli e tempi
espressi in tick, vanno quindi convertite in regole indipendenti dal frame rate,
non trascritte letteralmente.

## Stato attuale

### Regole già presenti o sostanzialmente corrette

- la pallina resta sulla Vaus finché il giocatore non preme il pulsante;
- una vita viene persa soltanto quando non rimangono palline attive;
- dopo la perdita di una vita i mattoni già distrutti restano distrutti;
- i mattoni normali valgono da 50 a 120 punti in base al colore;
- raccogliere una capsula assegna 1.000 punti;
- attraversare il portale assegna 10.000 punti;
- le tre trasformazioni persistenti della Vaus esistono già: catch, extend e
  laser;
- il catalogo contiene tutti e sette i tipi di capsula, incluso `disrupt`.

### Regole presenti ma incomplete o diverse dall'originale

| Area | Progetto attuale | Regola MSX da integrare |
| --- | --- | --- |
| Disruption | Il codice crea fino a tre palline, ma nessuno dei cinque livelli contiene la capsula. Le nuove velocità sono semplici moltiplicazioni. | Attivare esattamente tre palline nella stessa posizione, conservare lo stesso stadio di velocità e assegnare tre traiettorie discrete coerenti con quella corrente. |
| Velocità pallina | Aumento del 20% ogni 15 impatti con mattoni, fino a 90 impatti. | Stadi discreti; il contatore avanza a ogni impatto con pareti superiori/laterali e mattoni. La durata degli stadi segue la tabella `1,1,1,1,1,1,1,1,1,1,2,4,8,16,24,31`. I round 17-32 partono uno stadio più veloci. |
| Angolo pallina | Angolo continuo calcolato sul punto di impatto con la Vaus. | Sei fasce discrete sulla Vaus; dopo 40 rimbalzi sui bordi cambia la traiettoria di tutte le palline. Ogni 20 impatti sui mattoni oro cambia nuovamente la traiettoria. |
| Capsula slow | Annulla in blocco gli aumenti accumulati nel contatore locale. | Riduce di un solo stadio la velocità di tutte le palline attive, senza scendere sotto il minimo. |
| Catch | Trattiene la pallina senza scadenza. | Rilascio tramite azione oppure automatico dopo 240 tick originali; anche la pallina iniziale ha un timeout di 120 tick. I tick andranno convertiti in durate di gioco. |
| Mattoni argento | Sempre 4 colpi e 200 punti. | Round 1-8: 2 colpi/400 punti; 9-16: 3/600; 17-24: 4/800; 25-32: 5/1.000. |
| Capsule nei livelli | Ogni `BrickSpec` contiene già il tipo esatto da rilasciare e più capsule possono cadere insieme. | Il livello marca solo i mattoni abilitati al drop; il tipo viene scelto al momento. Una sola capsula può cadere, nessun drop con multiball, portale aperto o meno di 4 mattoni distruttibili rimasti. |
| Scelta capsule | Distribuzione completamente deterministica. | Tabelle pesate che non ripropongono catch, extend o laser già attivi; Break e Player usano contatori rari e stateful. Player può comparire una sola volta per partita. |
| Stato Vaus | Il nuovo power-up non azzera sempre in modo atomico quello precedente; una pallina catturata può rimanere nella lista interna. | Ogni capsula normalizza prima la Vaus. Catch, extend e laser sono mutuamente esclusivi; slow, disruption, break e player lasciano la Vaus normale e rilasciano eventuali palline catturate. |
| Laser | Ogni pressione crea un nuovo componente senza limite. | Massimo tre raffiche attive; una raffica colpisce un solo bersaglio e deve poter eliminare anche un alieno. |

Fonti principali: logica dei mattoni e della velocità in
[`disassembly.asm`](https://github.com/mcolom/arkanoid_msx_disasm/blob/20f5b7ba8e3d4ee04e0cfc051a3dfd98dbed233e/disassembly.asm#L7573-L7615),
variazione delle traiettorie in
[`disassembly.asm`](https://github.com/mcolom/arkanoid_msx_disasm/blob/20f5b7ba8e3d4ee04e0cfc051a3dfd98dbed233e/disassembly.asm#L7339-L7353),
e selezione/azioni delle capsule in
[`disassembly.asm`](https://github.com/mcolom/arkanoid_msx_disasm/blob/20f5b7ba8e3d4ee04e0cfc051a3dfd98dbed233e/disassembly.asm#L8557-L9105).

### Regole originariamente mancanti

1. **Vite extra legate al punteggio (integrato).** Si ottiene una vita a 20.000 punti, poi
   a 60.000 e successivamente ogni 60.000 punti (120.000, 180.000, ...). La
   capsula Player è un meccanismo aggiuntivo e separato.
2. **Alieni (integrato, da calibrare).** Il round 1 consente un alieno attivo, il round 2 due e dal round
   3 in poi tre. Il tentativo di spawn avviene ogni 240 tick e usa la porta più
   lontana dalla Vaus. Esistono quattro varianti di aspetto/movimento cicliche
   per round. Pallina, laser e Vaus li distruggono; la collisione con la Vaus
   non costa una vita. Ogni alieno vale 100 punti e fa rimbalzare la pallina.
3. **Progressione completa (integrata).** Il gioco MSX ha 32 round, mentre la versione
   arcade scelta come riferimento ha 32 round di mattoni seguiti da Doh. Il
   progetto deve mantenere intenzionalmente questa differenza dal port.
4. **Round finale con Doh (integrato).** Nel port MSX Doh occupa il round 32; nel percorso
   arcade del progetto sarà il round 33. Non ci sono capsule o alieni: Doh
   richiede 16 colpi, cambia colore quando viene colpito e può mantenere fino a
   tre proiettili diretti verso la Vaus. Un proiettile distrugge la Vaus. Alla
   sconfitta segue l'animazione di dissoluzione e il finale, non il ritorno al
   round 1.
5. **Pausa.** L'originale sospende esplicitamente aggiornamento e audio e mostra
   `PAUSE`. È una funzione di sessione, non solo un overlay.
6. **Schermata iniziale, demo e finale narrativo.** Fanno parte del ciclo
   completo del gioco, ma non sono necessari per rendere corretto il gameplay
   dei round e possono essere realizzati per ultimi.

Fonti: vite a punteggio in
[`disassembly.asm`](https://github.com/mcolom/arkanoid_msx_disasm/blob/20f5b7ba8e3d4ee04e0cfc051a3dfd98dbed233e/disassembly.asm#L2217-L2271),
spawn degli alieni in
[`disassembly.asm`](https://github.com/mcolom/arkanoid_msx_disasm/blob/20f5b7ba8e3d4ee04e0cfc051a3dfd98dbed233e/disassembly.asm#L4850-L4960),
Doh in
[`disassembly.asm`](https://github.com/mcolom/arkanoid_msx_disasm/blob/20f5b7ba8e3d4ee04e0cfc051a3dfd98dbed233e/disassembly.asm#L6723-L6855)
e conclusione della partita in
[`disassembly.asm`](https://github.com/mcolom/arkanoid_msx_disasm/blob/20f5b7ba8e3d4ee04e0cfc051a3dfd98dbed233e/disassembly.asm#L6382-L6443).

## Architettura proposta

```text
Arkanoid
├── GameSession
│   ├── score, highScore, lives, round
│   ├── nextExtraLifeScore
│   └── lifeCapsuleAlreadyAwarded
├── RoundController (evoluzione di BaseLevel)
│   ├── RoundRules
│   ├── BrickGrid
│   ├── BallDirector
│   ├── PowerUpDirector
│   └── EnemyDirector
└── componenti Flame
    ├── Ball / Starship / Brick / Capsule / Laser
    └── Alien / Doh / DohProjectile
```

- `GameSession` possiede solo lo stato che sopravvive al cambio round.
- `RoundRules` è una configurazione immutabile calcolata dal numero del round:
  resistenza e punti dei mattoni argento, stadio iniziale della pallina, limite
  alieni e variante grafica.
- `BallDirector` possiede contatori e stadi della fisica arcade; `Ball` continua
  a usare il resolver swept già presente per evitare tunneling.
- `PowerUpDirector` decide se e quale capsula generare. `BrickSpec` indica
  `dropsCapsule`, non il tipo concreto.
- `EnemyDirector` gestisce timer, cap degli alieni e porta di ingresso. I singoli
  alieni gestiscono soltanto movimento, animazione e collisioni locali.
- I tempi originali in tick vengono espressi come secondi di simulazione e
  aggiornati con `dt`, mantenendo il fixed step già usato dal progetto.

## Piano di integrazione

Ogni fase termina con test, `dart analyze`, suite Flutter, build Android debug
quando cambia il runtime e un commit dedicato prima di iniziare la fase
successiva.

### Fase 1 - Regole pure e sessione

- introdurre `GameSession` e `RoundRules` senza cambiare il rendering;
- spostare punteggio, vite, round e soglia della prossima vita fuori da
  `Arkanoid`/`BaseLevel`;
- implementare vite a 20k, 60k e poi ogni 60k;
- rendere resistenza e valore del mattone argento dipendenti dal round;
- mantenere tre tentativi totali iniziali, equivalenti alle due vite di riserva
  mostrate dall'MSX;
- aggiungere test tabellari per round 1, 8, 9, 16, 17, 24, 25 e 32.

### Fase 2 - Modello arcade della pallina

- aggiungere a ogni pallina `speedStage`, `speedProgress` e traiettoria discreta;
- avanzare il contatore su bordo e su qualunque mattone colpito, non soltanto su
  un mattone distrutto;
- applicare le soglie di accelerazione originali e lo stadio iniziale diverso
  dalla seconda metà del gioco;
- implementare le sei zone di rimbalzo della Vaus;
- implementare cambio traiettoria dopo 40 rimbalzi sui bordi e dopo 20 colpi sui
  mattoni oro;
- adattare Slow a un solo stadio e conservare il resolver continuo delle
  collisioni;
- coprire con test puri stadi, contatori e direzioni, lasciando i test di
  integrazione alle sole collisioni Flame.

### Fase 3 - Ciclo completo delle capsule

- sostituire il tipo fisso nei livelli con il flag `dropsCapsule`;
- introdurre il limite di una capsula in caduta e i blocchi con multiball,
  portale aperto e meno di quattro mattoni rimasti;
- implementare selezione pesata, esclusione della trasformazione già attiva e
  contatori rari di Break/Player;
- garantire che Player possa uscire una sola volta per partita;
- centralizzare la transizione dello stato della Vaus e rilasciare le palline
  catturate quando cambia power-up;
- aggiungere timeout di Catch e limite di tre raffiche laser attive.

### Fase 4 - Disruption completo (confermato)

Il comportamento attuale è stato validato nel gameplay ed è considerato
soddisfacente. Non sono previste altre modifiche in questa fase, per evitare di
sostituire un comportamento arcade funzionante con dettagli specifici MSX.

- rendere la capsula realmente ottenibile dalla selezione casuale;
- creare tre palline con posizione e stadio identici alla pallina sorgente e
  traiettorie divergenti derivate dalla tabella MSX;
- impedire nuovi drop finché sono attive più palline;
- verificare perdita delle palline una per volta, perdita della vita soltanto
  con l'ultima e pulizia completa su cambio round, portale e game over.

### Fase 5 - Alieni

- introdurre `EnemyDirector`, porte animate e un limite arcade configurabile;
- usare un intervallo di simulazione in secondi, indipendente dal frame rate;
- alternare le porte senza importare la scelta specifica del port MSX;
- implementare le quattro forme arcade e il comportamento rispetto ai mattoni;
- gestire collisioni con pallina, laser e Vaus, esplosione, suono e 100 punti;
- assicurare che gli alieni non siano necessari per completare il round e
  vengano rimossi durante ogni transizione.

Le scelte provvisorie da calibrare sono documentate in
`docs/arcade-behavior-decisions.md`.

### Fase 6 - Contenuti e progressione 1-32

- mantenere i layout arcade: il formato MSX usa una mappa da 132 celle, quello
  attuale e la fonte arcade adottata usano una griglia 16 x 13;
- estendere `LevelDefinition` con regole del round e marker di drop;
- portare e validare i round mancanti, includendo il numero atteso di mattoni
  distruttibili;
- rimuovere la progressione tramite modulo e rendere impossibile il ritorno
  silenzioso al round 1;
- aggiornare il level editor dopo la stabilizzazione del nuovo schema dati.

### Fase 7 - Doh (round 33) e finale (completata)

- modellare il round 33 come tipo di round distinto, senza griglia di mattoni;
- implementare hitbox di Doh, 16 colpi, feedback colore e rimbalzo corretto;
- implementare fino a tre proiettili, traiettoria iniziale verso la Vaus e
  perdita della vita al contatto;
- aggiungere sequenza di sconfitta, testo finale e ritorno al ciclo iniziale;
- coprire vittoria, morte durante il boss e ripristino del boss dopo una vita.

### Fase 8 - Ciclo esterno e rifinitura

- aggiungere pausa reale, title screen e demo opzionale;
- calibrare tempi, suoni e animazioni confrontando registrazioni a 60 Hz;
- documentare quali differenze dalla versione MSX sono intenzionali;
- aggiornare README e matrice di compatibilità delle regole.

## Criteri di accettazione globali

- nessuna regola dipende direttamente dal frame rate;
- ogni sorgente di punti passa da un solo servizio di sessione;
- una collisione può colpire un solo mattone per sotto-step;
- la Vaus ha un solo stato persistente tra normal, catch, extend e laser;
- tutti gli oggetti temporanei vengono rimossi su perdita vita e cambio round;
- i 32 round conducono a Doh e il suo completamento conduce al finale;
- non vengono copiati codice assembly o asset dal repository: si reimplementano
  soltanto i comportamenti osservabili. Prima di distribuire layout e asset
  originali va verificata separatamente la relativa licenza.

## Elementi intenzionalmente esclusi

- i due cheat della versione MSX;
- bug e routine dichiarate ma non operative, come l'accelerazione della pallina
  durante il fuoco laser;
- emulazione dei limiti del VDP o dei contatori a 8 bit;
- riproduzione byte-per-byte di casualità e timing: i test verificheranno
  invarianti e distribuzioni, non la sequenza del registro `R` dello Z80.
