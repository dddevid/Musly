# Piano di Implementazione UI/UX Spotify TV per Musly

Questo piano dettagliato descrive le modifiche necessarie per trasformare l'interfaccia utente di Musly in un'esperienza "Spotify TV-like" quando l'app viene eseguita in modalità TV (`isTvMode == true`). Attualmente, la modalità TV utilizza componenti desktop come la `DesktopNavigationSidebar`, dando l'impressione di un'app per PC. L'obiettivo è riprogettare la navigazione, il layout e il sistema di focus per l'utilizzo tramite D-Pad (telecomando).

## 1. Architettura della Shell Principale (`main_screen.dart` split)

**Attuale:** Il file `lib/screens/main/main_screen.dart` decide il layout in base a `_isLargeScreen(context)` (width >= 650), ricadendo sul layout Desktop per le TV e caricando `DesktopNavigationSidebar` e `DesktopPlayerBar`.
**Obiettivo:** Effettuare uno split architetturale inserendo un check esplicito per la modalità TV e caricando una struttura dedicata che separi nettamente le logiche TV da quelle Desktop.

*   **Modifica in `main_screen.dart`:**
    *   Ottenere `isTvMode`: `final isTv = Provider.of<TvDetectionService>(context).isTvMode;`
    *   Creare un branch nell'albero dei widget: Se `isTv` è vero, renderizzare un nuovo widget `TvMainScreen`.
    *   Il layout `TvMainScreen` deve essere uno `Scaffold` contenente una `Row` con la nuova `TvNavigationSidebar` a sinistra e un `Expanded(child: Navigator(...))` a destra per le schermate principali (Home, Search, Library).
    *   Rimuovere la `DesktopPlayerBar` dal layout TV. Sulla TV, non c'è una player bar globale. Sostituirla con un widget *Now Playing* compatto alla base della sidebar.

## 2. Navigazione Laterale (`TvNavigationSidebar`) e Stato di Espansione

La barra di navigazione in stile Spotify TV è minimale. Non deve usare hover da mouse ma essere reattiva al D-Pad tramite il sistema di focus.

*   **Creare `lib/widgets/navigation/tv_navigation_sidebar.dart`:**
    *   **Voci principali:** Home, Search, Your Library, Settings.
    *   **Gestione `isExpanded` e `FocusTraversalGroup`:**
        *   Racchiudere l'intera sidebar in un `FocusTraversalGroup` per gestire coerentemente il focus al suo interno ed evitare salti indesiderati.
        *   Mantenere uno stato locale `bool isExpanded = false`.
        *   Monitorare il focus (ad esempio con un `Focus` widget padre che avvolge la colonna della sidebar, intercettando `onFocusChange`). Se il focus entra in qualsiasi elemento della sidebar, `isExpanded` diventa `true`, rivelando le etichette testuali (tramite animazione). Se il focus esce verso i contenuti a destra, la sidebar si restringe mostrando solo le icone.
    *   **Gestione del Focus sulle singole voci:**
        *   Eliminare i `MouseRegion` usati nella versione Desktop.
        *   Utilizzare widget `Focus` per ogni voce. Quando focalizzato: applicare `Transform.scale(scale: 1.05)` e mostrare testo nero/scuro su sfondo bianco o grigio chiaro.

## 3. Home Screen TV e Navigazione a Scaffali (Shelves)

*   **Caroselli Orizzontali (Shelves):**
    *   Organizzare i contenuti in scaffali orizzontali (`ListView.builder` o liste scrollabili orizzontali).
    *   **Scroll Automatico tramite Focus:** Per garantire che l'elemento focalizzato sia sempre perfettamente visibile quando l'utente scorre lateralmente con il D-Pad, all'interno del callback `onFocusChange` di ciascuna card richiamare:
        `Scrollable.ensureVisible(context, alignment: 0.5, duration: const Duration(milliseconds: 300));`
*   **Focus sulle Card (White Border invece di Giallo):**
    *   Attualmente i bordi in focus o l'evidenziazione tendono a usare i colori di accento standard (spesso giallo o verde).
    *   Per rispecchiare lo stile Spotify TV, aggiornare il feedback visivo delle `MediaCard` e altre card TV per mostrare un **bordo solido bianco** ad alto contrasto (es. `border: Border.all(color: Colors.white, width: 3)`) e una leggera elevazione (`box-shadow`) quando `node.hasFocus` è true, rimuovendo il bordo giallo.

## 4. Schermate Ricerca, Libreria e Navigazione (Routing)

*   **Search Screen e Keyboard Handling:**
    *   Il campo di testo deve aprire la tastiera virtuale invocando `FocusNode.requestFocus()` su un `TextField`.
    *   È cruciale implementare la logica per il ritorno o la chiusura della tastiera: se l'utente preme invio o "giù", il focus deve scivolare fluidamente nella griglia dei risultati o categorie sottostante ("Sfoglia tutto").
*   **Library Screen e Routing delle Playlist:**
    *   Mostrare le playlist in una struttura a scaffali o griglia chiara e navigabile col D-Pad.
    *   **Navigation Routing per le Playlist:** Quando viene selezionata una playlist, utilizzare correttamente il routing passando da `LibraryScreen` alla schermata di dettaglio, per esempio `Navigator.pushNamed(context, '/playlist', arguments: playlistId)`.
    *   Nel momento in cui si apre il dettaglio della playlist, posizionare *automaticamente* il focus iniziale (utilizzando `autofocus: true` o richiedendo esplicitamente il focus) sul pulsante "Play" principale o sul primo brano della lista, così l'utente è subito pronto all'azione.

## 5. Player a Schermo Intero (`now_playing_screen.dart` Full-Screen TV Refactor)

Attualmente, `now_playing_screen.dart` è concepito per mobile e tablet (utilizza gesture di trascinamento e swipe).

*   **Refactor per la modalità TV:**
    *   Creare un albero di layout dedicato per la TV (`if (isTvMode) return TvNowPlayingScreen()`).
    *   **Rimuovere i Gesture Detectors:** Sulla TV, lo swipe su/giù e sinistra/destra con le dita non esiste. Rimuovere `GestureDetector` e gestire tutto tramite eventi fisici del telecomando.
    *   **Layout Immersivo:**
        *   Sfondo con effetto blur profondo ottenuto dalla copertina dell'album (`BlurredGradientBackground`).
        *   Lato Sinistro: Copertina gigante dell'album.
        *   Lato Destro o in basso: Testo enorme per il Titolo e l'Artista (leggibilità ottimizzata per distanze di 3-4 metri).
    *   **Controlli di Riproduzione Focalizzabili:**
        *   Creare una riga orizzontale di icone (Shuffle, Previous, Play/Pause, Next, Repeat).
        *   Il pulsante Play/Pause deve essere enorme e ricevere l'autofocus iniziale.
    *   **Barra di Avanzamento e Scrubbing:**
        *   Avvolgere la barra di avanzamento o il widget del tempo in un nodo di focus che, se attivo, interpreti i comandi D-Pad Destra/Sinistra per lo scrubbing rapido (avanti e indietro nel brano).

## 6. Accessibilità, Telecomando e Tema

*   **Tema Scuro:** Forzare il tema in modalità dark quando su TV per garantire il massimo contrasto visivo e comfort oculare, in linea con l'identità TV.
*   **Telecomando (`TvRemoteScope`):** Assicurarsi che `TvRemoteScope` (già presente) mappi correttamente il tasto "Back" hardware del telecomando per chiudere modali, uscire dal player a schermo intero e tornare indietro nella cronologia del `Navigator`, per poi uscire dall'app solo se ci si trova alla root.
