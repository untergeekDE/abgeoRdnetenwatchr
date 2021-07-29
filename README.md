# abgeoRdnetenwatchr
Wrapper für die [API von abgeordnetenwatch.de](https://abgeordnetenwatch.de/api)

# API ansteuern

Wenn sie mit der richtigen URL aufgerufen wird, liefert die API ein JSON zurück, das die gewünschten Daten enthält. Zum Teil sind diese Daten etwas verschachtelt und müssen in R wieder auseinandergefaltet werden. 

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

Jeder Typ Entität hat seine eigenen Datenpunkte (also: Spalten in der Rückgabetabelle) - in der Regel kann man nach diesen Werten filtern. 

## Beispiel-Aufrufe

### Wahlen (BTW2021 hat die ID 128)
* [/parliament-periods?type=election&parliament=5](https://www.abgeordnetenwatch.de/api/v2/parliament-periods?type=election&parliament=5)

### Kandidatenliste pro Wahlkreis:
* (ist nicht; indirekt über Wahlperiode herausfinden und filtern)

### Wahlkreisliste zur BTW: 
* [/constituencies?parliament_period=128](https://www.abgeordnetenwatch.de/api/v2/constituencies?parliament_period=128)
* [/constituencies?parliament_period=128&number=178](https://www.abgeordnetenwatch.de/api/v2/constituencies?parliament_period=128&number=178) (Rheingau-Taunus)
* [/parliament-periods/128?related_data=constituencies](https://www.abgeordnetenwatch.de/api/v2/parliament-periods/128?related_data=constituencies) (in der related data)

### Kandidatenwahl zur BTW: 
* [/candidacies-mandates?parliament_period=128](https://www.abgeordnetenwatch.de/api/v2/candidacies-mandates?parliament_period=128)

### Kandidat:innen einer Partei
indirekt, über referenziertes Objekt politician und Daten da
* /candidacies-mandates?parliament_period=128&politician[entity.party.entity.id]=16(https://www.abgeordnetenwatch.de/api/v2)

### Kandidat:innen eines Wahlkreises
* [/candidacies-mandates?electoral_data[entity.constituency]=10235](https://www.abgeordnetenwatch.de/api/v2/candidacies-mandates?electoral_data[entity.constituency]=10235)
* [/candidacies-mandates?constituency=10235](https://www.abgeordnetenwatch.de/api/v2/candidacies-mandates?constituency=10235) (Kurzform)
* [/candidacies-mandates?constituency_nr=178&parliament_period=128](https://www.abgeordnetenwatch.de/api/v2/candidacies-mandates?constituency_nr=178&parliament_period=128) (Kurzform und BTW21)

### Landesliste zur BTW: 
* [/electoral-lists?parliament_period=128](https://www.abgeordnetenwatch.de/api/v2/electoral-lists?parliament_period=128)
* [/electoral-lists?parliament_period=128&name[cn]=Hessen](https://www.abgeordnetenwatch.de/api/v2/electoral-lists?parliament_period=128&name[cn]=Hessen)
...aber was macht man damit? Related data gibt's nicht...
...Kandidaten filtern: 
* [/candidacies-mandates?electoral_data[entity.electoral_list]=362](https://www.abgeordnetenwatch.de/api/v2/candidacies-mandates?electoral_data[entity.electoral_list]=362)

### Mitglieder der SPD in der Datenbank
(Filter über das related_data-Element party)
* [/politicians?party[entity.id]=1](https://www.abgeordnetenwatch.de/api/v2/politicians?party[entity.id]=1)

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
