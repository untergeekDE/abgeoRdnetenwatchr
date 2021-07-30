#' abgeoRdnetenwatchr
#'
#' R wrapper for the politics tracking platform abgeordnetenwatch.de
#' via its v2 API.
#'
#'@author Jan Eggers <jan.eggers@hr.de>
# 
#'


require("jsonlite")
require("dplyr")
require("stringr")
require("lubridate")


# ---- Definition section ----

#' Entities
#' 

entities <- as.factor(c("parliaments",
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

# Filter modifiers: Instead of simply filtering for values equal to the 
# fiilter variable, use one of the following: 

modifiers <- factor(c("[eq]",  # "equal", ist der Standard-Operator "="
                      "[gt]",  # - "greater than", entspricht ">"
                      "[gte]", # - "greater than equal", entspricht ">="
                      "[lt]",  # - "less than", entspricht "<"
                      "[lte]", # - "less than equal", entspricht "<="
                      "[ne]",  # - "not equal", entspricht "<>" oder "!="
                      "[sw]",  # - "STARTS_WITH"
                      "[cn]",  # - "CONTAINS"
                      "[ew]")) # - "ENDS_WITH"

#' Request single object by ID 
#' 
#' @description
#' `aw_get_id` requests data for one single object
#' 
#' @details
#' This function is used to request one single object, belonging to an entity class,
#' defined by its ID. 
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
  aw_json <<- try(fromJSON(query_string), silent = TRUE)
  if (aw_json$meta$status == "ok") {
    return(as.data.frame(aw_json$data))
  } else {
    return(FALSE)
  }
}

t <- aw_get_id("parliaments",8,try="1", tryAgain="2")

#' Request table of objects 
#' 
#' @description
#' `aw_get_table` requests data as a data frame.
#' 
#' @details
#' This function is used to request one single object, belonging to an entity class,
#' defined by its ID. 
#' 
#' @examples 
#' aw_get_table("parliaments")
#' 
#' @param entity Entity class, as listed in the factor entities
#' @param ... List of filters 
#' 
#' @export
aw_get_table <- function(entity,...) {
  # check parameters: Entity parameter ok?
  if (!entity %in% entities) {
    stop("Undefined entity")
  }
  # List of arguments to be used as filters
  filters <<- list(...)
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
                             names(filters[i]),"=",filters[i])
    } 
  }
  #TODO: 
  # Wenn ein Argument ein Vektor ist (Length >1),
  # iteriere durch alle Elemente des Vektors und füge sie dem
  # Ergebnis-dataframe über bind_rows() hinzu
  
  # Bugfixing: Print query string
  cat(query_string)
  # Try to read JSON
  aw_json <- try(fromJSON(query_string), silent = TRUE)
  # If successful, turn into dataframe and return. 
  #
  # Due to the nested structure of the JSON, 
  # some columns of these dataframes will contain lists rather than
  # single-value columns. For me, being a rather mediocre R coder, 
  # I solved this by using bind_cols() and a selection of sub-indices.
  if (aw_json$meta$status == "ok") {
    return(as.data.frame(aw_json$data))
  } else {
    return(FALSE)
  }
}

# ---- Macros ----
  


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


# Aufgabe: 
# - Erstelle eine Liste aller hessischen Kandidat*innen nach Wahlkreis.
# - Referenziere darin Partei, Listenplatz, Wiederwahl ja/nein
# - Kreuzreferenz zum Politiker/in
# -- aw-Link Profil
# -- aw-Link Abstimmungsverhalten
# -- aw-Link Fragen/Antworten (mit Rahmendate
wahlkreise_df <- aw_get_table("constituencies",parliament_period=128,range_end=500) %>%
  filter(number %in% 167:188) %>% 
  select(id,wk=number,wk_name=name)

k_df <- NULL
for (i in wahlkreise_df$id) {
  k_df <- k_df %>% bind_rows(aw_get_table("candidacies-mandates",constituency=i))
}



# Liste hessische Kandidat:innen aufbauen: Zuerst die aw-Kandidaten-id...
kand_he_df <- k_df %>% select(c_id=id) %>% 
  # ..dann aw-Wahlkreis-id...
  bind_cols(k_df$electoral_data$constituency %>% select(id)) %>%
  # ...dann Wahlkreisnummer und -name...
  left_join(wahlkreise_df,by="id") %>%
  # ...dann aw-id des Politikers... (Name kommt später)
  bind_cols(k_df$politician %>% select(politician_id = id, name=label, 
                                       profile_url=abgeordnetenwatch_url)) %>%
  # ...dann Partei und aw-Partei-id...
  bind_cols(k_df$party %>% select(party_id = id, party=label)) %>% 
  # ...dann Listenplatz
  bind_cols(k_df$electoral_data %>% 
              select(listenplatz=list_position)) %>% 
  arrange(wk)

# Sehr stumpfes Base R hier, und dann auch noch schlechtes: 
# Alle Zeilen abfragen und 
p_df <- NULL
for (i in 1:nrow(kand_he_df)) {
  p_df <- p_df %>% 
    bind_rows(aw_get_table("politicians",id=kand_he_df$politician_id[i]))
}

kand_he_df <- kand_he_df %>% 
  left_join(p_df %>% select(
    politician_id=id, 
    titel=field_title,
    vorname=first_name,
    nachname=last_name,
    geburtsname=birth_name,
    geschlecht=sex,
    geburtsjahr=year_of_birth,
    ausbildung=education,
    wohnort=residence,
    beruf=occupation,
    aw_fragen=statistic_questions,
    aw_beantwortet=statistic_questions_answered
  ), by="politician_id") %>% 
  select(-c_id,-id,-name)
  
# Write to files
library(openxlsx)  
write.xlsx(kand_he_df,"./daten/tabelle-direktkandidaten-aw.xlsx")
write.csv(kand_he_df,"./daten/tab_aw.csv")

# Try to copy to Google bucket for Datawrapper publication
try(system('gsutil -h "Cache-Control:no-cache, max_age=0" cp daten/tab_aw.csv gs://d.data.gcp.cloud.hr.de/tab_aw.csv'),
silent=TRUE)

