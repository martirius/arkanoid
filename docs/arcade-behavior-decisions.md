# Decisioni di compatibilità arcade

La versione arcade del 1986 è il riferimento principale del progetto. Il
disassemblato MSX resta utile per comprendere strutture e stati interni, ma una
regola del port non viene trasferita automaticamente al gioco.

## Alieni

La prima integrazione usa le quattro forme e gli sprite arcade già presenti:
Konerd, Pyradok, Tri-sphere e Opopo. Gli ostacoli deviano la pallina, possono
essere distrutti dalla pallina, dal laser o dalla Vaus, assegnano 100 punti e
non sono necessari per completare il round.

Le seguenti regole del port MSX non vengono importate:

- limite progressivo di uno, due e tre alieni nei primi round;
- scelta della porta più lontana dalla Vaus;
- intervallo espresso in 240 tick MSX;
- traiettorie ricavate dalle tabelle specifiche del port.

La configurazione corrente usa al massimo tre alieni, alterna le due porte e
genera un nuovo ostacolo ogni sei secondi di gioco attivo. Questi valori sono
isolati in `EnemyDirector` e andranno calibrati confrontando una registrazione
del cabinato arcade, senza modificare collisioni o ciclo di vita del round.

## Progressione e livelli

Il catalogo segue i 32 round con mattoni della versione arcade; Doh è il round
33 e verrà aggiunto come tipo di round distinto. I layout dei round 6-32 sono
stati trascritti dalla mappa arcade di VGMaps nella griglia 16 x 13 già usata
dal progetto. Dopo il completamento del round 32 il livello rimane nello stato
concluso finché Doh non è implementato, invece di ricominciare in silenzio dal
round 1.

La mappa mostra colori e tipi di mattone, ma non i marker nascosti delle
capsule. Per i round 6-32 questi marker sono quindi distribuiti in modo
deterministico solo sui mattoni colorati e distruttibili. La loro posizione
esatta andrà calibrata da una fonte arcade verificabile prima del rilascio.

Fonte dei layout:
[Arkanoid - Rounds (VGMaps)](https://vgmaps.com/Atlas/Arcade/Arkanoid-Rounds.png).
