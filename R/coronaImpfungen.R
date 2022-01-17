einwohnerZahlLkEbe <- 144091 # as of 2020-12-31, Bayerisches Landesamt für Statistik
buergerAb80LkEbe <- 9430 # as of 2021-01-08

germanNumberFormat <- function(x, accuracy = 1, scale = 1, prefix = "", suffix = "") {
  number(
    x,
    accuracy = accuracy,
    scale = scale,
    prefix = prefix,
    suffix = suffix,
    decimal.mark = ",",
    big.mark = "."
  )
}

impfungenRaw <- read_delim(
  file = "data/corona-impfungen/impfungenLandkreis.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    datum = col_date(format = "%Y-%m-%d"),
    erstimpfungen = col_integer(),
    zweitimpfungen = col_integer(),
    erstimpfungenAb80 = col_integer(),
    zweitimpfungenAb80 = col_integer(),
    registriert = col_integer()
  )
)

arcgisImpfungenRaw <- read_delim(
  file = "data/corona-impfungen/arcgisImpfungen.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    datum = col_date(format = "%Y-%m-%d"),
    erstimpfungen = col_integer(),
    zweitimpfungen = col_integer(),
    drittimpfungen = col_integer(),
    impfdosen = col_integer(),
    impfdosenNeu = col_integer()
  )
)

enrichImpfungenData <- function(x) {
  return (
    x %>%
      complete(datum = seq(min(datum), max(datum), "days"), fill = list()) %>%
      mutate(
        impfdosen7tageMittel = (impfdosen - lag(impfdosen, 7)) / 7,
        impfidenz = (impfdosen - lag(impfdosen, 7)) / einwohnerZahlLkEbe * 100000,
        erstImpfidenz = (erstimpfungen - lag(erstimpfungen, 7)) / einwohnerZahlLkEbe * 100000
      ) %>%
      mutate(
        impfdosenFilled = impfdosen,
        impfdosenLast = lag(impfdosen),
        erstimpfungenFilled = erstimpfungen,
        erstimpfungenLast = lag(erstimpfungen),
        zweitimpfungenFilled = zweitimpfungen,
        zweitimpfungenLast = lag(zweitimpfungen),
        drittimpfungenFilled = drittimpfungen,
        drittimpfungenLast = lag(drittimpfungen)
      ) %>%
      fill(impfdosenFilled, erstimpfungenFilled, zweitimpfungenFilled, drittimpfungenFilled, .direction = "up") %>%
      fill(impfdosenLast, erstimpfungenLast, zweitimpfungenLast, drittimpfungenLast, .direction = "down") %>%
      add_count(impfdosenFilled, impfdosenLast, name = "impfdosenDays") %>%
      add_count(erstimpfungenFilled, erstimpfungenLast, name = "erstimpfungenDays") %>%
      add_count(zweitimpfungenFilled, zweitimpfungenLast, name = "zweitimpfungenDays") %>%
      add_count(drittimpfungenFilled, drittimpfungenLast, name = "drittimpfungenDays") %>%
      mutate(
        impfdosenNeuProTag = (impfdosenFilled - impfdosenLast) / impfdosenDays,
        impfdosenFilled = NULL,
        impfdosenLast = NULL,
        impfdosenDays = NULL,
        erstimpfungenNeuProTag = (erstimpfungenFilled - erstimpfungenLast) / erstimpfungenDays,
        erstimpfungenFilled = NULL,
        erstimpfungenLast = NULL,
        erstimpfungenDays = NULL,
        zweitimpfungenNeuProTag = (zweitimpfungenFilled - zweitimpfungenLast) / zweitimpfungenDays,
        zweitimpfungenFilled = NULL,
        zweitimpfungenLast = NULL,
        zweitimpfungenDays = NULL,
        drittimpfungenNeuProTag = (drittimpfungenFilled - drittimpfungenLast) / drittimpfungenDays,
        drittimpfungenFilled = NULL,
        drittimpfungenLast = NULL,
        drittimpfungenDays = NULL
      )
  )
}

impfungenMerged <- bind_rows(
  impfungenRaw %>%
    filter(datum < min(arcgisImpfungenRaw$datum)) %>%
    transmute(
      datum,
      erstimpfungen,
      zweitimpfungen,
      drittimpfungen = 0,
      impfdosen = erstimpfungen + zweitimpfungen,
      impfdosenNeu = impfdosen - lag(impfdosen)
    ) %>% enrichImpfungenData(),
  arcgisImpfungenRaw %>%
    transmute(
      datum,
      erstimpfungen,
      zweitimpfungen,
      drittimpfungen,
      impfdosen,
      impfdosenNeu
    ) %>% enrichImpfungenData()
)


arcgisImpfungenNachEinrichtungRaw <- read_delim(
  file = "data/corona-impfungen/arcgisImpfungenNachEinrichtung.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    datum = col_date(format = "%Y-%m-%d"),
    einrichtung = readr::col_factor(levels = c("Impfzentrum", "Praxis", "Kreisklinik")),
    erstimpfungen = col_integer(),
    zweitimpfungen = col_integer(),
    drittimpfungen = col_integer(),
    impfdosen = col_integer()
  )
)
arcgisImpfungenNachEinrichtung <- arcgisImpfungenNachEinrichtungRaw %>%
  group_by(einrichtung) %>%
  complete(datum = seq(min(arcgisImpfungenNachEinrichtungRaw$datum), max(arcgisImpfungenNachEinrichtungRaw$datum), "days"), fill = list()) %>%
  fill(erstimpfungen, zweitimpfungen, drittimpfungen, impfdosen, .direction = "down") %>%
  mutate(
    impfdosenNeu = impfdosen - lag(impfdosen)
  )

arcgisImpfungenNachAlter <- read_delim(
  file = "data/corona-impfungen/arcgisImpfungenNachAlter.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    datum = col_date(format = "%Y-%m-%d"),
    einrichtung = readr::col_factor(levels = c("Impfzentrum", "Praxis", "Kreisklinik")),
    altersgruppe = readr::col_factor(levels = c("0-19", "20-29", "30-39", "40-49", "50-59", "60-69", "70-79", "80+")),
    erstimpfungen = col_integer(),
    zweitimpfungen = col_integer(),
    drittimpfungen = col_integer()
  )
)

impfungenAlterMerged <- bind_rows(
  impfungenRaw %>%
    filter(datum < min(arcgisImpfungenNachAlter$datum)) %>%
    filter(!is.na(erstimpfungenAb80)) %>%
    transmute(
      datum,
      altersgruppe = "Unbekannt",
      erstimpfungen = erstimpfungen - erstimpfungenAb80 - erstimpfungenHausaerzte,
      zweitimpfungen = zweitimpfungen - zweitimpfungenAb80 - zweitimpfungenHausaerzte,
      drittimpfungen = 0
    ),
  impfungenRaw %>%
    filter(datum < min(arcgisImpfungenNachAlter$datum)) %>%
    filter(!is.na(erstimpfungenAb80)) %>%
    transmute(
      datum,
      altersgruppe = "80+",
      erstimpfungen = erstimpfungenAb80,
      zweitimpfungen = zweitimpfungenAb80,
      drittimpfungen = 0
    ),
  arcgisImpfungenNachAlter %>%
    filter(einrichtung == "Impfzentrum") %>%
    transmute(
      datum,
      altersgruppe,
      erstimpfungen,
      zweitimpfungen,
      drittimpfungen
    )
) %>%
  mutate(
    altersgruppe = factor(altersgruppe, levels = c("Unbekannt", "0-19", "20-29", "30-39", "40-49", "50-59", "60-69", "70-79", "80+"))
  )

maxDatum = max(impfungenMerged$datum, arcgisImpfungenNachEinrichtung$datum)
minDatum = min(impfungenMerged$datum, arcgisImpfungenNachEinrichtung$datum)

ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

  ns <- NS(id)
  tagList(
    h2("Corona-Impfungen im Landkreis Ebersberg"),

    fluidRow(
      {
        lastRow <- impfungenMerged %>% filter(!is.na(erstimpfungen)) %>% slice_tail()
        valueBox(
          germanNumberFormat(lastRow$erstimpfungen / einwohnerZahlLkEbe, accuracy = 0.1, scale = 100, suffix = "%"),
          paste0("Erstimpfquote (absolut: ", germanNumberFormat(lastRow$erstimpfungen), ")"),
          color = "blue",
          icon = icon("star-half-alt")
        )
      },
      {
        lastRow <- impfungenMerged %>% filter(!is.na(zweitimpfungen)) %>% slice_tail()
        valueBox(
          germanNumberFormat(lastRow$zweitimpfungen / einwohnerZahlLkEbe, accuracy = 0.1, scale = 100, suffix = "%"),
          paste0("Zweitimpfquote (absolut: ", germanNumberFormat(lastRow$zweitimpfungen), ")"),
          color = "blue",
          icon = icon("star")
        )
      },
      {
        lastRow <- impfungenMerged %>% filter(!is.na(impfidenz)) %>% slice_tail()
        valueBox(
          germanNumberFormat(lastRow$impfidenz, accuracy = 0.1),
          paste0("7-Tage-Impfidenz (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ")"),
          color = "blue",
          icon = icon("tachometer-alt")
        )
      }
    ),

    fluidRow(
      box(
        title = "Geimpfte Personen",
        {
          print("plot_ly geimpfte")
          plot_ly(impfungenMerged %>% filter(!is.na(erstimpfungen)), x = ~datum, yhoverformat = ",d", height = 350) %>%
            add_trace(y = ~erstimpfungen, type = "scatter", mode = "none", fill = 'tozeroy', fillcolor = "#74a9cf", name = "Erstimpfungen") %>%
            add_trace(y = ~zweitimpfungen, type = "scatter", mode = "none", fill = 'tozeroy', fillcolor = "#0570b0", name = "Zweitimpfungen") %>%
            add_trace(y = ~drittimpfungen, type = "scatter", mode = "none", fill = 'tozeroy', fillcolor = "#023858", name = "Drittimpfungen") %>%
            plotly_default_config() %>%
            plotly_time_range() %>%
            plotly_hide_axis_titles() %>%
            plotly_build()
        },
        {
          lastRow <- impfungenMerged %>% filter(!is.na(erstimpfungen)) %>% slice_tail()
          paste0("Aktuell (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ") haben ", germanNumberFormat(lastRow$erstimpfungen), " Menschen mindestens eine Erstimpfung erhalten, davon ", germanNumberFormat(lastRow$zweitimpfungen), " eine Zweitimpfung und ", germanNumberFormat(lastRow$drittimpfungen), " eine Drittimpfung.")
        }
      ),
      box(
        title = "7-Tage-Impfidenz",
        {
          plot_ly(filter(impfungenMerged, !is.na(impfidenz)), x = ~datum, yhoverformat = ",.1f", height = 350) %>%
            add_trace(y = ~ impfidenz, type = "scatter", mode = "lines", name = "Gesamt-Impfidenz", size = I(2), color = I("#000000")) %>%
            add_trace(y = ~ erstImpfidenz, type = "scatter", mode = "lines", name = "Erst-Impfidenz", size = I(2), color = I("#74a9cf")) %>%
            plotly_default_config() %>%
            plotly_time_range() %>%
            plotly_hide_axis_titles() %>%
            plotly_build()
        },
        {
          lastRow <- impfungenMerged %>% filter(!is.na(impfidenz)) %>% slice_tail()
          paste0("Die 7-Tage-Impfidenz (Anzahl verimpfter Dosen in den letzten 7 Tagen pro 100.000 Einwohner) liegt zum ", format(lastRow$datum, "%d.%m.%Y"), " bei ", germanNumberFormat(lastRow$impfidenz, accuracy = 0.1), ".")
        }
      ),
    ),

    fluidRow(
      box(
        title = "Verabreichte Impfdosen pro Tag",
        {
          plot_ly(filter(impfungenMerged, !is.na(erstimpfungenNeuProTag)), x = ~datum, yhoverformat = ",", height = 350) %>%
            add_trace(y = ~drittimpfungenNeuProTag, type = "bar", name = "Drittimpfungen", color = I("#023858"), width = 24*60*60*1000) %>%
            add_trace(y = ~zweitimpfungenNeuProTag, type = "bar", name = "Zweitimpfungen", color = I("#0570b0"), width = 24*60*60*1000) %>%
            add_trace(y = ~erstimpfungenNeuProTag, type = "bar", name = "Erstimpfungen", color = I("#74a9cf"), width = 24*60*60*1000) %>%
            layout(barmode = 'stack') %>%
            plotly_default_config() %>%
            plotly_time_range() %>%
            plotly_hide_axis_titles() %>%
            plotly_build()
        },
        {
          lastRow <- impfungenMerged %>% filter(!is.na(impfdosenNeuProTag)) %>% slice_tail()
          paste0("Zuletzt (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ") wurden ", germanNumberFormat(lastRow$impfdosenNeuProTag, accuracy = 1), " Impfdosen pro Tag verabreicht.")
        }
      ),
      box(
        title = "Verabreichte Impfdosen pro Tag nach Einrichtung",
        {
          plot_ly(filter(arcgisImpfungenNachEinrichtung, !is.na(impfdosenNeu)), x = ~datum, yhoverformat = ",", height = 350) %>%
            add_trace(y = ~impfdosenNeu, type = "bar", name = ~einrichtung, width = 24*60*60*1000) %>%
            layout(barmode = 'stack') %>%
            plotly_default_config() %>%
            plotly_time_range() %>%
            plotly_hide_axis_titles() %>%
            plotly_build()
        },
        {
          impfdosen7Tage <- arcgisImpfungenNachEinrichtung %>%
            filter(!is.na(impfdosenNeu)) %>%
            slice_tail(n = 7) %>%
            summarise(impfdosen7Tage = sum(impfdosenNeu), datum = max(datum)) %>%
            pivot_wider(names_from = einrichtung, values_from = impfdosen7Tage)

          paste0("In den letzen 7 Tagen (Stand:\u00A0", format(impfdosen7Tage$datum, "%d.%m.%Y"), ") wurden ", germanNumberFormat(impfdosen7Tage$Impfzentrum), " Impfdosen im Impfzentrum, ", germanNumberFormat(impfdosen7Tage$Praxis, accuracy = 1), " Impfdosen in Arztpraxen und ", germanNumberFormat(impfdosen7Tage$Kreisklinik, accuracy = 1), " Impfdosen in der Kreisklinik verabreicht.")
        }
      ),
    ),

    fluidRow(
      box(
        title = "Erstgeimpfte nach Altersgruppe",
        {
          plot_ly(impfungenAlterMerged, x = ~datum, yhoverformat = ",", height = 350) %>%
            add_trace(y = ~erstimpfungen, type = "scatter", mode = "none", fill = 'tonexty', color = ~altersgruppe, stackgroup = 'one', alpha = 1, alpha_stroke = 1, opacity=1, colors = c('#eeeeee','#1b9e77','#d95f02','#7570b3','#e7298a','#66a61e','#e6ab02','#a6761d','#005a32')) %>%
            plotly_default_config() %>%
            plotly_time_range() %>%
            plotly_hide_axis_titles() %>%
            plotly_build()
        },
      ),
      box(
        title = "Verabreichte Impfdosen insgesamt",
        {
          plot_ly(filter(impfungenMerged, !is.na(impfdosen)), x = ~datum, height = 350) %>%
            add_trace(y = ~impfdosen, type = "scatter", mode = "lines", name = "Impfdosen", size = I(2), yhoverformat = ",d") %>%
            plotly_default_config() %>%
            plotly_time_range() %>%
            plotly_hide_axis_titles() %>%
            plotly_build()
        },
        {
          lastRow <- impfungenMerged %>% filter(!is.na(impfdosen)) %>% slice_tail()
          paste0("Bislang (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ") wurden im Landkreis Ebersberg ", germanNumberFormat(lastRow$impfdosen), " Impfdosen verabreicht.")
        }
      ),
    ),

    fluidRow(
      box(
        title = "Datengrundlage und Methodik",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("Datengrundlage ist seit dem 21. April 2021 die <a href=\"https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services\">ArcGIS-API</a>, die für das <a href=\"https://experience.arcgis.com/experience/dc7f97a7874b47aebf1a75e74749c047\">COVID-19 Dashboard Ebersberg</a> verwendet wird. Diese Daten stammen vom Landratsamt Ebersberg, welches wiederum die Daten von Impfzentrum, Arztpraxen und Kreisklinik bereitstellt. Die Daten werden automatisch abgerufen und dargestellt. Werden auf dieser Seite offensichtlich falsche Daten (z.&nbsp;B. negative Zahl an verabreichter Impfdosen) angezeigt, liegt dies häufig an fehlerhaften Originaldaten, die automatisch verwendet werden.")),
          p(HTML("Zuvor wurden die Daten der Homepage des <a href = \"https://lra-ebe.de/\">Landratsamts Ebersberg</a> (<a href=\"https://lra-ebe.de/aktuelles/aktuelle-meldungen/\">Aktuelle Pressemeldungen</a>, <a href=\"https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/corona-pressearchiv/\">Corona-Pressearchiv</a>) sowie der Seite des <a href=\"https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/impfzentrum/\">Impfzentrums Ebersberg</a> entnommen. Diese Daten wurden vorrangig händisch und teils auch automatisiert bis zum 13. Juli 2021 gesammelt; diese Daten werden jedoch zugunst der ArcGIS-Daten nur bis zum 20. April 2021 verwendet.")),
        ),
      ),
    ),
  )
})


# Define the server logic for a module
server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {
    }
  )
}

plotly_default_config <- function(p) {
  p %>%
    config(displayModeBar = FALSE) %>%
    config(locale = "de") %>%
    layout(xaxis = list(fixedrange = TRUE, rangemode = 'tozero')) %>%
    layout(yaxis = list(fixedrange = TRUE)) %>%
    layout(hovermode = "x") %>%
    layout(dragmode = FALSE) %>%
    identity()
}

plotly_time_range <- function(p) {
  return(
    p %>%
      # legend above plot
      layout(legend = list(bgcolor = "#ffffffaa", orientation = 'h', y = 1.2, yanchor = "bottom")) %>%
      # default time selection
      layout(xaxis = list(range = list(maxDatum-91, maxDatum+1))) %>%
      layout(xaxis = list(
        rangeselector = list(
          buttons = list(
            list(count = 1, label = "1 Monat", step = "month", stepmode = "backward"),
            list(count = 3, label = "3 Monate", step = "month", stepmode = "backward"),
            list(count = 6, label = "6 Monate", step = "month", stepmode = "backward"),
            list(step = "all", label = "Gesamt")
          )
        ),
        rangeslider = list(type = "date")
      )) %>%
      config(doubleClick = FALSE) %>%
      identity()
  )
}

plotly_hide_axis_titles <- function(p) {
  return(
    p %>%
      layout(xaxis = list(title = list(standoff = 0, font = list(size = 1)))) %>%
      layout(yaxis = list(title = list(standoff = 0, font = list(size = 1)))) %>%
      layout(margin = list(r = 0, l = 0, t = 0, b = 4, pad = 0))
  )
}
