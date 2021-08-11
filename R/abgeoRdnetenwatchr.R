#' abgeoRdnetenwatchr
#'
#' R-Wrapper für abgeordnetenwatch.de
#' für die v2 API.
#'
#'@author Jan Eggers <jan.eggers@hr.de>
#'


require("jsonlite")
require("dplyr")
require("stringr")
require("lubridate")


# ---- Definitionen ----

#' Entities
#' 
#' @details 
#' Die Abgeordnetenwatch-Datenbank ist in Objekten organisiert, die "Entitäten" heißen. 
#' Jedes Objekt hat eine eindeutige ID in der Datenbank - und kann Beziehungen zu anderen Entitäten haben (z.B. ist eine Wahlperiode mit einem Parlament und den dort vertretenen Abgeordneten verknüpft; eine Abstimmung mit den beteiligten Abgeordneten und ihrem Abstimmungsverhalten). 
#' Die Objekte sind immer fest einer Wahl bzw. einer Wahlperiode zugeordnet: Beispielsweise ist die ID eines Wahlkreises in der Bundestagswahl 2017 eine andere als die ID desselben Wahlkreises in der BTW2021. (Beispiel Rheingau-Taunus: ID zur BTW2017 - 9188, ID in der Legislaturperiode 2017-2021 - 4302, ID zur BTW2021 - 10235.)

entities <- factor(c("parliaments",
              "parliament-periods",
              "politicians",
              "candidacies-mandates",
              "committees",
              "committee-menderships",
              "polls",
              "votes",
              "parties",
              "fractions",
              "electoral-lists",
              "constituencies",
              "election-programs",
              "sidejobs",
              "sidejob-organisations",
              "topics",
              "cities",
              "countries"))

# Filter-Vergleichsoperatoren: Diese Strings sorgen dafür, dass die API
# anders vergleicht. Beispiel: `name[cn]=Hessen` sucht nach Einträgen, die 
# den String "Hessen" enthalten (contain)

modifiers <- factor(c("[eq]",  # "equal", ist der Standard-Operator "="
                      "[gt]",  # - "greater than", entspricht ">"
                      "[gte]", # - "greater than equal", entspricht ">="
                      "[lt]",  # - "less than", entspricht "<"
                      "[lte]", # - "less than equal", entspricht "<="
                      "[ne]",  # - "not equal", entspricht "<>" oder "!="
                      "[sw]",  # - "STARTS_WITH"
                      "[cn]",  # - "CONTAINS", nicht case-sensitive
                      "[ew]")) # - "ENDS_WITH"

#' @title Liste der Bundesländer
#'
#' @description Eine Indexdatei mit der ID, dem Länderschlüssel aus der AGS und dem Namen des Parlaments
#'
#' @format A data frame with 17 rows and 4 variables:
#' \describe{
#'   \item{id}{die interne aw-ID}
#'   \item{lkz}{der Länderschlüssel aus der AGS (Bund=0)}
#'   \item{label}{die Länderbezeichnung}
#'   \item{llabel_external_long}{die Bezeichnung des Parlaments}
#' }
#' @source \url{http://www.destatis.de/}
"laender"

# ---- Funktionen für Datenabruf ----
#' Datenabfrage
#' 
#' @description
#' `aw_get_id` fragt Daten für ein Objekt nach seiner ID ab
#' 
#' @details
#' Abfrage eines einzelnen Objekts aus der aw-Datenbank. Gibt ein Listen-Objekt zurück, das dann mit der üblichen R-Notation mit $ ausgelesen werden kann. Der Typ der Entität muss bekannt sein und angegeben werden; IDs sind nicht eindeutig: 9188 bezeichnet ein Entität vom Typ candidacy-mandate und vom Typ constituency.   
#' 
#' @examples 
#' aw_get_id("politicians",1)
#' 
#' @param entity Entity class, as listed in the factor entities
#' @param id 
#' @param ... List of filters 
#' 
#' @export
aw_get_id <- function(entity,id,...) {
  # check parameters
  if (!entity %in% entities) {
    stop("Undefined entity")
  }
  filters <- list(...)
  # construct API string 
  query_string <- paste0("https://www.abgeordnetenwatch.de/",
                         "api/v2",
                         "/",entity,
                         "/",id)
  for(i in filters) {
    cat(i)
  } 
  aw_json <<- try(fromJSON(URLencode(query_string)), silent = TRUE)
  if (aw_json$meta$status == "ok") {
    return(aw_json$data)
  } else {
    return(FALSE)
  }
}


#' aw_get_table 
#' 
#' @description
#' `aw_get_table` - Datenabfrage in ein Dataframe
#' 
#' @details
#' Abruf der Daten und Formatierung als Dataframe. Angegeben werden muss immer der Typ der abgefragten Daten - welche Art Entitäten wollen wir aus der Datenbank lesen? - optional sind Filter. Die Filter können dabei entweder in Form eines R-Parameters übergeben werden oder als String. Fragt die API in Blöcken zu 100 Ergebnissen ab. 
#' 
#' @examples 
#' aw_get_table("parliaments")
#' aw_get_table("constituencies",parliament_period=128)
#' aw_get_table("parliaments","label[cn]=hessen")
#' 
#' @param entity Typ der abgefragten Datenobjekte (Entitäten)
#' @param ... List of filters 
#' 
#' @returns df mit den Daten (abhängig von der abgefragten Entität)
#' 
#' @export
aw_get_table <- function(entity,...) {
  # check parameters: Entity parameter ok?
  if (!entity %in% entities) {
    stop("Undefined entity")
  }
  # List of arguments to be used as filters
  filters <- list(...)
  # Basic API string 
  query_string <- paste0("https://www.abgeordnetenwatch.de/",
                         "api/v2",
                         "/",entity)
  # If any filters are set, take each argument and convert to string
  if (!is.null(filters)) {
    query_string <- paste0(query_string,"?")
    # If you felt like it, you could do thorough error-checking here. 
    # We don't do that yet. 
    for(i in 1:length(filters)) {
      # filters is a list; loop through the number of elements,
      # construct a string formed "(name)=(value)", and add to query.
      query_string <- paste0(query_string,
                             ifelse(str_sub(query_string,-1,-1)!="?","&",""),
                             names(filters[i]),
                             ifelse(names(filters[i])!="","=",""),
                             filters[i])
    } 
  }
  #TODO: 
  # Wenn ein Argument ein Vektor ist (Length >1),
  # iteriere durch alle Elemente des Vektors und füge sie dem
  # Ergebnis-dataframe über bind_rows() hinzu
  
  # Try to read JSON
  aw_json <<- try(fromJSON(URLencode(query_string)), silent = TRUE)
  # If successful, turn into dataframe and return. 
  if (aw_json$meta$status == "ok") {
    t <- jsonlite::flatten(aw_json$data)
  } else {
    # Fehler beim Lesen
    return(FALSE)
  }
  # Mehr Treffer als Rückgabewerte?
  if (!is.null(aw_json$meta$result$count)) {
    if (aw_json$meta$result$count < aw_json$meta$result$total) {
      for (i in seq(from=100,to=aw_json$meta$result$total,by=100)) {
        t <- bind_rows(t,aw_get_table(entity,...,range_start=i))
        
      }
    }
  }
  return(t)
}

# ---- Makros für typische Aufgaben ----

#' aw_wahl 
#' 
#' @description
#' `aw_wahl` gibt die ID(s) für eine Wahl zu einem Parlament zurück
#' 
#' @details
#' Mit aw_wahl kann man sich die IDs einer Wahl suchen lassen, und zwar entweder über den Namen (oder die Länderkennzahl) oder die aw-ID, dazu das Jahr (es wird das nächste gültige gesucht), und die Einschränkun.
#' 
#' @examples 
#' aw_wahl("Bundestag") liefert die ID der aktuellen BTW
#' aw_wahl("Hessen 2021") liefert die ID der nächsten Landtagswahl 2022
#' aw_wahl("Bundestag",2021) liefert 128 (die ID der aktuellen Wahl)
#' 
#' @param p ein String mit dem Namen des Parlaments ("Hessen" - auch in der Form: BLxx mit der Länderkennzahl aus der AGS, etwa "BL06" für den Hessischen Landtag); wenn p numerisch ist, wird es als aw-ID des Parlaments identifiziert (z.B.: 11 für Hessen)
#' @param y eine Jahreszahl der gesuchten Wahl bzw. Wahlperiode
#' @param strict Boolean-Variable: TRUE, wenn nur genaue Treffer akzeptiert werden sollen; in der Default-Einstellung sucht die Funktion nach dem nächsten passenden Wert
#'  
#' @returns Integer-Wert mit erstem Treffer
#' 
#' @export
aw_wahl <- function(p,y=year(today()),strict=FALSE) {
  p_id <- as.numeric(p)
  # Als aw-ID interpretieren, falls eine Zahl. Andernfalls: 
  # keine numerische ID, nach String suchen 
  if (is.na(as.numeric(p))) {
    # Bundesländerkennzahl?
    if(grepl(p,"^BL")) {
      p_id <- laender %>% filter(lkz==as.numeric(str_sub(p,3))) %>% pull(id)
    } else {
      # String suchen
      p_id <- laender %>% filter(str_detect(label,p) | 
                                   str_detect(label_external_long,p)) %>% pull(id)
    }
    # Nichts gefunden? Abbruch
    if (is.na(p_id)) return(FALSE)
  } 
  # Frage für das Parlament eine Liste der in Frage kommenden Wahlen ab
  wahlen <- aw_get_table("parliament-periods",parliament=p_id) 
    # Such die Wahl, die am nächsten liegt
    wp <- wahlen %>%
      filter(!is.na(election_date)) %>% 
      mutate(d = abs(year(election_date)-y)) %>% 
      arrange(d) %>% 
      slice_head(n=1)
    if (strict & wp$d > 0) {
      return(FALSE)
    } else {
      return(wp$id)
  }
}

#' aw_wahlperiode 
#' 
#' @description
#' `aw_wahlperiode` gibt die ID(s) für eine Wahlperiode zu einem Parlament zurück
#' 
#' @details
#' Mit aw_wahlperiode kann man sich die IDs einer Wahl bzw. Wahlperiode suchen lassen, und zwar entweder über den Namen (oder die Länderkennzahl) oder die aw-ID, dazu das Jahr (es wird das nächste gültige gesucht). 
#' Wahlen sind in der aw-Datenbank gewissermaßen besondere Wahlperioden von i.d.R. 2 Monaten Länge. Mit dem Filter Wahl=FALSE kann man dafür sorgen, dass sie nicht gefunden werden; sonst listet die Funktion sie auch auf. 
#' 
#' @examples 
#' aw_wahlperiode("Bundestag",2021) liefert 111 (die Bundestags-Wahlperiode 2017-2021)
#' aw_wahlperiode("Bundestag",2020) liefert 111 (die Bundestags-Wahlperiode 2017-2021)
#' aw_wahlperiode("Bundestag",2018,wahl=TRUE) liefert 111 (weil die Wahlperiode näher am Zeitpunkt liegt)
#' aw_wahlperiode("Bundestag",2017,wahl=TRUE) liefert 50 (die Bundestagswahl 2017) - entspricht aw_wahl()
#' aw_wahl("BL06",2018,wahl=FALSE) liefert (Hessischer Landtag, Wahlperiode 2018-2022)
#' 
#' @param p ein String mit dem Namen des Parlaments ("Hessen" - auch in der Form: BLxx mit der Länderkennzahl aus der AGS, etwa "BL06" für den Hessischen Landtag); wenn p numerisch ist, wird es als aw-ID des Parlaments identifiziert (z.B.: 11 für Hessen)
#' @param y eine Jahreszahl der gesuchten Wahl bzw. Wahlperiode
#' @param wahl Boolean-Variable: TRUE, wenn auch eine Wahl gesucht werden darf, FALSE, wenn nur eine Wahlperiode gefunden werden soll
#' @param strict Boolean-Variable: TRUE, wenn nur genaue Treffer akzeptiert werden sollen; in der Default-Einstellung sucht die Funktion nach dem nächsten passenden Wert
#'  
#' @returns Integer-Wert mit erstem Treffer
#' 
#' @export
aw_wahlperiode <- function(p,y=year(today()),wahl=FALSE,strict=FALSE) {
  p_id <- as.numeric(p)
  # Als aw-ID interpretieren, falls eine Zahl. Andernfalls: 
  # keine numerische ID, nach String suchen 
  if (is.na(as.numeric(p))) {
    # Bundesländerkennzahl?
    if(grepl(p,"^BL")) {
      p_id <- laender %>% filter(lkz==as.numeric(str_sub(p,3))) %>% pull(id)
    } else {
      # String suchen
      p_id <- laender %>% filter(str_detect(label,p) | 
                                   str_detect(label_external_long,p)) %>% pull(id)
    }
    # Nichts gefunden? Abbruch
    if (is.na(p_id)) return(FALSE)
  } 
  # Frage für das Parlament eine Liste der in Frage kommenden Wahlen ab
  wahlen <- aw_get_table("parliament-periods",parliament=p_id) 
  # Such die Wahl, die am nächsten liegt
  # Jahres-Parameter y umwandeln
  if (is.numeric(y)) {
    yy <- ymd(paste0(y,"-01-01"))
  } else {
    yy <- as_date(y)
  }
  wp <- wahlen %>%
    # Wenn wahl=FALSE, filtere "election" aus; wenn wahl=TRUE, nimm alles
    filter(type=="legislature" | wahl) %>%
    mutate(d = abs(as.numeric(as_date(start_date_period)-yy))) %>% 
    arrange(d) %>% 
    slice_head(n=1)
  if (strict & year(wp$start_date_period)!=y) {
    return(FALSE)
  } else {
    return(wp$id)
  }
}



#' aw_wahlkreise
#' 
#' @description
#' `aw_wahlkreise` gibt eine Wahlkreisliste für eine Wahl-ID zurück. 
#' 
#' @details
#' Diese Funktion ruft zu einer Wahl bzw. Wahlperiode die zugehörigen Wahlkreise ab. Die IDs der Wahl bzw. der Wahlperiode ist immer fest einem Parlament und einer Zeit zugeordnet. Als Rückgabe bekommt man eine Liste der IDs, Wahlkreisnummern und Wahlkreisnamen zu dieser Wahl - die Wahlkreis-IDs sind ebenfalls fest einer Wahl zugeordnet, d.h.: ein und derselbe Wahlkreis (z.B.: Wiesbaden) hat bei der Bundestagswahl 2017 eine andere ID als bei der darauffolgenden Wahlperiode oder der Bundestagswahl 2021 - oder bei der Landtagswahl, die einem völlig anderen Parlament zugeordnet ist. 
#' 
#' @examples 
#' aw_wahlkreise(128)
#' aw_wahlkreise(aw_wahl("Bund",2017)) oder
#' aw_wahl("Bund",2021) %>% aw_wahlkreise()
#' aw_wahlkreise(aw_wahl("Hessen",2018,wahl=TRUE))
#' 
#' @param electionID - aw-ID der Wahl bzw. Wahlperiode
#' 
#' @returns df mit der constiuency-ID, der Wahlkreisnummer und den Wahlkreisnamen
#' 
#' @export
aw_wahlkreise <- function(electionID=NULL) {
  if (is.null(electionID)) {
    stop("Keine Wahl/periode angegeben")
    return(FALSE)
  }
  r <- aw_get_table("constituencies",parliament_period=electionID,range_end=500) %>%
    select(id,wk=number,wk_name=name)
  return(r)
}

# ---- Sample query strings ----
# You may try these by adding these strings to 
#   http://www.abgeordnetenwatch.de/api/v2
# and pasting them to the Firefox address bar. 
# Returns a JSON with the data. 

# Wahlen (BTW2021 hat die ID 128)
# /parliament-periods?type=election&parliament=5

# Kandidatenliste pro Wahlkreis:
# (ist nicht; indirekt über Wahlperiode herausfinden und filtern)

# Wahlkreisliste zur BTW: 
# /constituencies?parliament_period=128
# /constituencies?parliament_period=128&number=178 (Rheingau-Taunus)
# /parliament-periods/128?related_data=constituencies (in der related data)

# Kandidatenwahl zur BTW: 
# /candidacies-mandates?parliament_period=128

# Kandidat:innen einer Partei
# - indirekt, über referenziertes Objekt politician und Daten da
# /candidacies-mandates?parliament_period=128&politician[entity.party.entity.id]=16

# Kandidat:innen eines Wahlkreises
# /candidacies-mandates?electoral_data[entity.constituency]=10235
# /candidacies-mandates?constituency=10235 (Kurzform)
# /candidacies-mandates?constituency_nr=178&parliament_period=128 (Kurzform und BTW21)

# Landesliste zur BTW: 
# /electoral-lists?parliament_period=128
# /electoral-lists?parliament_period=128&name[cn]=Hessen

# ...aber was macht man damit? Related data gibt's nicht...
# ...Kandidaten filtern: 
# /candidacies-mandates?electoral_data[entity.electoral_list]=362

# Mitglieder der SPD in der Datenbank
# (Filter über das related_data-Element party)
# /politicians?party[entity.id]=1

# API gibt normalerweise 100 Objekte zurück. 

# Fragen: 
# - Warum gibt die candidacy-Filterung nach Landesliste Hessen nur 32 Objekte zurück?
# - Sind Landeslisten und Wahlkreise unique zu einer Wahlperiode? - JA (Rheingau-Taunus 2017: ID 9188, Rheingau-Taunus 2021: 10235)


# ---- Zukunftsmusik ----
# Was cool wäre: Eine Konstruktion, die dplyr-artige Pipes ermöglicht: 
# aw_wahl("Hessen",2018) %>% 
#   aw_wahlkreise() %>% 
#   filter(id == aw_wahlkreis("Rhein-Taunus")) %>% 
#   aw_kandidaten() 
#
# Ist noch nicht zu Ende gedacht, weil aw_wahlkreis() ja verschiedenste
# Entitäten zurückgeben kann - und das Ganze auch mit Vektoren/Listen funktionieren sollte