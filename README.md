# abgeoRdnetenwatchr
Wrapper für die [API von abgeordnetenwatch.de](https://abgeordnetenwatch.de/api)

Ziel: Schränkt die Möglichkeiten der API so weit ein, dass man sie gebrauchen kann: 
- Objekt abfragen, z.B.: Wahl, Parlament
-- Problem: Anzahl der Rückgabewerte verändert sich mit der Entität
-- Problem: Filter sinnvoll anwenden: welche Filter sind wo zulässig?
-- 
- Relationen abfragen
-- Was macht man dann mit denen?

Beispielaufgaben: 
- Gib mir alle amtierenden Abgeordneten im Parlament x
- Such mir alle Kandidaten für einen Wahlkreis
- Such mir alle Ausschussmitglieder, die für Gesetz X mit ja gestimmt haben
- Gib mir das Abstimmungsverhalten der Abgeordneten der Partei X als Tabelle


Idee: Neben einer generischen Abfrage-Matrix ein paar starre Funktionen, 
die in der Regel Vektoren zurückgeben (Beispiel: Abgeordnete - nur IDs), allenfalls als zweispaltige data.frames (ID, value - Beispiel: Gesetz, Stimmverhalten)



## Installation

## Function calls


## Entitäten

Die Abgeordnetenwatch-Datenbank ist in Objekten organisiert, die "Entitäten" heißen. 

Jedes Objekt hat eine eindeutige ID in der Datenbank - und kann Beziehungen zu anderen Entitäten haben (z.B. ist eine Wahlperiode mit einem Parlament und den dort vertretenen Abgeordneten verknüpft; eine Abstimmung mit den beteiligten Abgeordneten und ihrem Abstimmungsverhalten). 

Die Objekte sind immer fest einer Wahl bzw. einer Wahlperiode zugeordnet: Beispielsweise ist die ID eines Wahlkreises in der Bundestagswahl 2017 eine andere als die ID desselben Wahlkreises in der BTW2021. (Beispiel Rheingau-Taunus: ID zur BTW2017 - 9188, ID in der Legislaturperiode 2017-2021 - 4302, ID zur BTW2021 - 10235.)

Diese 18 Typen von Entitäten gibt es: 

- **parliaments** (die 16 Landesparlamente, der Bundestag und das EU-Parlament)
- **parliament-periods"** (die Wahlperioden bzw. Wahlen - die werden gewissermaßen als gesonderte Wahlperiode gehandhabt)
- **politician/s** (Politiker:innen - Einzelpersonen: Mandatsträger und Kandidaten)
- **candidacies-mandate/s**
- **committee/s** (Ausschüsse)
- **committee-membership/s** (Mitgliedschaften in Ausschüssen)
- **poll/s** (Abstimmungen im Parlament)
- **vote/s** (Stimmen)
- **party/ies** (Parteien)
- **fractions** (Fraktionen im Parlament)
- **electoral-list/s** (Wahllisten)
- **constituency/cies** (Wahlkreise)
- **election-program/s** (Wahlprogramme)
- **sidejobs** (Nebentätigkeiten)
- **sidejob-organisation/s** (Organisationen, in denen Nebentätigkeiten verzeichnet sind)
- **topics** (Themen)
- **cities** (nur im Zusammenhang mit Nebentätigkeiten: Ort der Nebentätigkeit)
- **countries** (nur im Zusammenhang mit Nebentätigkeiten: Land der Nebentätigkeit)

## Todo

- Examples and use cases
- Convert to a proper R library (anybody any advice how to do this?)
-- roxygen Commands and tags
-- Tests
- /posts/search call (invitation only!)
- /leaderboard call
- /lists call
- /lists/:listid/accounts call
- /ctpost/:id call (hidden, possibly deprecated)
- clean up the rather messy parameter structure for the calls
- Error handling
