# abgeoRdnetenwatchr
Wrapper für die [API von abgeordnetenwatch.de](https://abgeordnetenwatch.de/api)

# API ansteuern

Basis-URL für einen API-Aufruf ist: 

```https://www.abgeordnetenwatch.de/api/v2/(Entität)```

Wenn sie mit den richtigen Parametern aufgerufen wird, liefert die API ein JSON zurück, das die gewünschten Daten enthält. Zum Teil sind diese Daten etwas verschachtelt; hier werden sie über jsonlite::flatten() in Dataframes gebügelt, die dann aber unterschiedliche und unterschiedlich viele Spalten haben. 



### Entitäten

Die Abgeordnetenwatch-Datenbank ist in Objekten organisiert, die "Entitäten" heißen. 

Jedes Objekt hat eine eindeutige ID in der Datenbank - und kann Beziehungen zu anderen Entitäten haben (z.B. ist eine Wahlperiode mit einem Parlament und den dort vertretenen Abgeordneten verknüpft; eine Abstimmung mit den beteiligten Abgeordneten und ihrem Abstimmungsverhalten). 

Die Objekte sind immer fest einer Wahl bzw. einer Wahlperiode zugeordnet: Beispielsweise ist die ID eines Wahlkreises in der Bundestagswahl 2017 eine andere als die ID desselben Wahlkreises in der BTW2021. (Beispiel Rheingau-Taunus: ID zur BTW2017 - 9188, ID in der Legislaturperiode 2017-2021 - 4302, ID zur BTW2021 - 10235.)

Diese 18 Typen von Entitäten gibt es: 

- **parliaments** (die 16 Landesparlamente, der Bundestag und das EU-Parlament)
- **parliament-periods** (die Wahlperioden bzw. Wahlen - die werden gewissermaßen als gesonderte Wahlperiode gehandhabt)
- **politicians** (Politiker:innen - Einzelpersonen: Mandatsträger und Kandidaten)
- **candidacies-mandates**
- **committees** (Ausschüsse)
- **committee-memberships** (Mitgliedschaften in Ausschüssen)
- **polls** (Abstimmungen im Parlament)
- **votes** (Stimmen)
- **parties** (Parteien)
- **fractions** (Fraktionen im Parlament)
- **electoral-lists** (Wahllisten)
- **constituencies** (Wahlkreise)
- **election-programs** (Wahlprogramme)
- **sidejobs** (Nebentätigkeiten)
- **sidejob-organisations** (Organisationen, in denen Nebentätigkeiten verzeichnet sind)
- **topics** (Themen)
- **cities** (nur im Zusammenhang mit Nebentätigkeiten: Ort der Nebentätigkeit)
- **countries** (nur im Zusammenhang mit Nebentätigkeiten: Land der Nebentätigkeit)

Jeder Typ Entität hat seine eigenen Datenpunkte (also: Spalten in der Rückgabetabelle) - in der Regel kann man nach diesen Werten filtern. 

### Paginierung

Die API gibt standardmäßig 100 Ergebnisse zurück, wenn man mehr braucht, muss man mit ```range_end``` (max. 1000) mehr Ergebnisse anfordern oder mit ```range_start``` bzw. ```page``` paginieren. 

Die Funktion ````aw_get_table()``` hat eine Paginierung schon eingebaut: wenn mehr als 100 Treffer zurückgegeben werden, holt sie in 100er-Blöcken all diese Treffer ab. (Vorsicht: damit kann man die API ziemlich beschäftigen.)

## Funktionen

### Direktabruf

* aw_get_id(entity,id) - ruft genau ein Objekt aus der Datenbank ab und gibt es als Liste zurück
* aw_get_table(entity,...) - ruft Trefferlisten aus der Datenbank ab (und zwar alle, auch wenn es mehr als 100 Treffer sind)
* aw_exists(entity,id) - prüft, ob es eine Entität diesen Typs mit dieser ID gibt

### Makros

Funktionen, die häufige Abrufen formalisieren und erleichtern sollen

* aw_wahl() - sucht die ID einer Wahl
* aw_wahlperiode() - sucht die ID einer Wahl oder Wahlperiode
* aw_wahlkreise() - 
* aw_kandidaten() - listet die Kandidat:innen zu einer Wahl oder einem Wahlkreis auf

## Todo

- aw_kandidaten() ausbauen: weniger Rückgabewerte, df als Parameter ermöglichen
- aw_personen() - generische Funktion zur Personenrecherche
- aw_personen() auch aktuelles Mandat, Liste von Entscheidungen, Antworten, Nebentätigkeiten ausspucken lassen
- Liste Beispielaufrufe um Funktionen ergänzen

## Beispiel-Aufrufe


### Wahlen zum BTW (parliament=5)

* API-Call: [/parliament-periods?type=election&parliament=5](https://www.abgeordnetenwatch.de/api/v2/parliament-periods?type=election&parliament=5)
* Funktionsaufruf: ```aw_get_table("elections",parliament=5)```

Gibt eine Liste zurück mit Wahlen und Wahlperioden. Die #btw2021 hat die ID 128.

* Siehe auch: ```aw_wahl("Bund",2021)``` gibt 128 zurück. 

### Wahlkreisliste zur BTW: 
* [/constituencies?parliament_period=128](https://www.abgeordnetenwatch.de/api/v2/constituencies?parliament_period=128)
* [/constituencies?parliament_period=128&number=178](https://www.abgeordnetenwatch.de/api/v2/constituencies?parliament_period=128&number=178) (einen Wahlkreis ausfiltern: Rheingau-Taunus)
* [/parliament-periods/128?related_data=constituencies](https://www.abgeordnetenwatch.de/api/v2/parliament-periods/128?related_data=constituencies) (in der related data steckt die Liste der Wahlkreise)
* Funktionsaufruf: ```aw_get_table("constituencies",parliament_period=128)```
* Funktionsaufruf: ```aw_wahlkreise(aw_wahl("Bund",2021))```

### Kandidaten zur BTW: 
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