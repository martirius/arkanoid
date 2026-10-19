# Decisioni di compatibilità arcade

La versione arcade del 1986 è il riferimento principale del progetto. Il
disassemblato MSX resta utile per comprendere strutture e stati interni, ma una
regola del port non viene trasferita automaticamente al gioco.

## Alieni

La prima integrazione usa le quattro forme e gli sprite arcade già presenti:
Konerd, Pyradok, Tri-sphere e Opopo. Gli ostacoli deviano la pallina, possono
essere distrutti dalla pallina, dal laser o dalla Vaus, assegnano 100 punti e
non sono necessari per completare il round.

Il progetto permette di scegliere il profilo arcade Easy o Hard. Entrambi
mantengono tre slot disponibili; cambia il ritmo con cui vengono occupati:

- tre slot disponibili fin dal primo round;
- una sola forma per round, scelta ciclicamente ogni quattro round;
- porta di ingresso sullo stesso lato della Vaus;
- in Hard gli slot vengono riempiti appena la sequenza della porta lo consente;
- in Easy il primo alieno entra normalmente, mentre gli ingressi successivi
  vengono distanziati di due secondi;
- sequenze e tempi di animazione ricavati dalle tabelle arcade.

La difficoltà non riduce il numero massimo di alieni. Movimento, accelerazione
e reazioni agli ostacoli usano le quattro coppie di tabelle arcade; anche gli
urti fra i tre alieni modificano le rispettive direzioni. Non vengono importate
le tabelle del port MSX.

## Progressione e livelli

Il catalogo segue i 32 round con mattoni della versione arcade; Doh è il round
33 e verrà aggiunto come tipo di round distinto. I layout dei round 6-32 sono
stati trascritti dalla mappa arcade di VGMaps nella griglia 16 x 13 già usata
dal progetto. Dopo il completamento del round 32 il livello rimane nello stato
concluso finché Doh non è implementato, invece di ricominciare in silenzio dal
round 1.

La ROM non associa marker nascosti ai mattoni. Quando viene distrutto un
mattone colorato, la routine arcade decide a runtime se rilasciare una capsula;
una capsula già in caduta, il multiball, il portale aperto e meno di quattro
mattoni distruttibili rimasti impediscono un nuovo rilascio.

Fonte dei layout:
[Arkanoid - Rounds (VGMaps)](https://vgmaps.com/Atlas/Arcade/Arkanoid-Rounds.png).

## Continue e crediti

La schermata riprende dalla ROM arcade le stringhe `TO CONTINUE GAME`,
`BEFORE TIMER REACHES "0"` e il conteggio iniziale da 9, adattando le istruzioni
al pulsante FIRE, alla tastiera e al touch. Ogni nuova partita dispone di tre
crediti virtuali; continuare ne consuma uno, ripristina tre vite e ricrea il
round corrente, conservando punteggio e progressione della sessione. Come
nell'arcade, Doh non permette continue.

## Traiettoria della pallina

I cambi automatici di traiettoria dopo 40 rimbalzi sui bordi o 20 colpi sui
mattoni oro appartengono al port MSX e non vengono applicati. La traiettoria
cambia soltanto in seguito a una collisione o all'impatto con la Vaus, evitando
che una pallina del Disruption possa deviare un'altra pallina in volo.

## Doh

Il round 33 è un tipo di round distinto, senza mattoni, capsule o alieni. Doh
richiede 16 colpi, assegna 1.000 punti per colpo e perde tutti i danni accumulati
quando il giocatore perde una vita. Può mantenere al massimo tre proiettili,
diretti verso la posizione della Vaus al momento dello sparo.

Lo spritesheet arcade e i due suoni già presenti nel progetto vengono usati per
ingresso, feedback dei colpi e dissoluzione. Velocità e intervallo dei proiettili
restano valori da calibrare su una registrazione arcade; la sequenza finale è
per ora limitata al messaggio conclusivo e al ritorno al round 1.
