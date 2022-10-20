utils <- new.env()
sys.source("R/utils.R", envir = utils, chdir = FALSE)

hgv <- read_delim(
  file = "data/schulen/hgvJahresberichte.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    schuljahresbeginn = col_integer(),
    schulleiter = readr::col_factor(),
    schuelerSchuljahresbeginn = col_integer(),
    zugaenge = col_integer(),
    abgaenge = col_integer(),
    schuelerSchuljahresende = col_integer(),
    schuelerMaennlich = col_integer(),
    schuelerWeiblich = col_integer(),
    kommentar = col_character(),
  )
) %>% mutate(
    schueler = coalesce(schuelerSchuljahresbeginn, schuelerSchuljahresende)
  )

schulleiter <- hgv %>%
  group_by(schulleiter) %>%
  summarise(
    anfang = min(schuljahresbeginn),
    ende = max(schuljahresbeginn),
    .groups = "drop"
  ) %>% mutate(
    jahre = ende - anfang + 1,
  )


ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

  ns <- NS(id)
  tagList(
    h2("Humboldt-Gymnasium Vaterstetten"),

    fluidRow(
      box(
        title = "Schülerzahlen",
        width = 6,
        radioGroupButtons(
          inputId = ns("plotTotalTextSwitch"),
          label = NULL,
          choices = c("Ohne Text" = "empty", "Mit Kommentaren" = "comments", "Mit Schulleitern" = "schulleiter")
        ),
        plotlyOutput(ns("plotTotal")),
        p({
          lastRow <- hgv %>% filter(!is.na(schueler)) %>% slice_tail()
          paste0("Im Schuljahr ", lastRow$schuljahresbeginn, "/", lastRow$schuljahresbeginn+1, " haben ", utils$germanNumberFormat(lastRow$schueler), " Schüler:innen das Humboldt-Gymnasium besucht, davon ", utils$germanNumberFormat(lastRow$schuelerMaennlich), " männlich und ", utils$germanNumberFormat(lastRow$schuelerWeiblich)," weiblich.")
        }),
        p("Es wird bevorzugt die Schülerzahl zum schuljahresbeginn dargestellt; ist diese nicht bekannt, wird die Schülerzahl zum Schuljahresende verwendet."),
      ),
      box(
        title = "Schülerzahlen nach Geschlecht",
        width = 6,
        radioGroupButtons(
          inputId = ns("plotNachGeschlechtSwitch"),
          label = NULL,
          choices = c("Absolut" = "absolute", "Relativ" = "relative")
        ),
        plotlyOutput(ns("plotNachGeschlecht")),
        p("Seit dem Schuljahr 2006/2007 gibt es mehr weibliche Schülerinnen als männliche Schüler am HGV. Davor waren stets die Jungs in der Überzahl, mit dem Schuljahr 1994/1995 als Ausnahme, in dem Geschlechterparität herrschte."),
        p(HTML('Warum für diese Grafik nicht rosa/blau als Geschlechter-Farbgebung verwendet wurde, sondern lila/türkis (nach Fraser Lyness, Director of Graphic Journalism bei The Telegraph): <a href="https://blog.datawrapper.de/gendercolor/">https://blog.datawrapper.de/gendercolor/</a>'))
      ),
    ),

    fluidRow(
      box(
        title = "Unterjährige Zugänge / Abgänge",
        width = 6,
        {
          plot_ly(data = hgv, x = ~schuljahresbeginn, textposition = "outside") %>%
            add_trace(y = ~zugaenge, name = "Zugänge", type = "bar", text = ~zugaenge, marker = list(color = "#069a2e"), hovertemplate = "%{text} Zugänge<extra></extra>") %>%
            add_trace(y = ~-abgaenge, name = "Abgänge", type = "bar", text = ~abgaenge, marker = list(color = "#c9211e"), hovertemplate = "%{text} Abgänge<extra></extra>") %>%
            plotly_default_config() %>%
            plotly_time_range() %>%
            layout(yaxis = list(title = "Schüler:innen", tickformat = ",d")) %>%
            layout(xaxis = list(title = "")) %>%
            layout(barmode = "relative") %>%
            plotly_build()
        },
      ),
      box(
        title = "Amtszeiten der Schulleiter",
        width = 6,
        {
          plot_ly(data = schulleiter, y = ~schulleiter, x = ~jahre, type = 'bar', orientation = 'h', text = ~paste0(jahre, " Schuljahre\n", anfang, "/", anfang+1, " – ", ende, "/", ende+1), hoverinfo = "none") %>%
            plotly_default_config() %>%
            layout(yaxis = list(title = "", categoryorder = "total ascending")) %>%
            plotly_build()
        },
      ),
    ),

    fluidRow(
      box(
        title = "Datengrundlage",
        width = 12,
        status = "primary",
        solidHeader = TRUE,
        tagList(
          p(HTML('Datenquelle sind die Jahresberichte des Humboldt-Gymnasiums Vaterstetten. Vielen Dank an alle Lehrkräfte und Privatleute, die diese zur Verfügung gestellt haben!'))
        ),
      ),

      box(
        title = "Mithilfe gesucht!",
        width = 12,
        status = "info",
        solidHeader = TRUE,
        tagList(
          p(HTML('Für einige Jahre fehlen noch (genaue) Daten. Haben Sie die passenden Jahresberichte oder vergleichbare Quellen parat? Dann freuen wir uns über eine Datenspende an <a href="mailto:felix@vaterstetten-in-zahlen.de">felix@vaterstetten-in-zahlen.de</a> oder gleich via <a href="https://github.com/fxedel/vaterstetten-in-zahlen">GitHub</a>')),
          p("Insbesondere wären folgende Jahresberichte hilfreich:"),
          tags$ul(
            tags$li("Schuljahre 1970/1971 bis 1974/1975 (zur Vervollständigung und Verifizierung der vorhandenen Daten)"),
            tags$li("Schuljahr 1976/1977 (fehlt bislang komplett)"),
          ),
          p("Außerdem fehlen folgende Daten, die in den Jahresberichten nicht mehr enthalten sind:"),
          tags$ul(
            tags$li("Schuljahre ab 1998/1999: Unterjährige Zu- und Abgänge"),
          ),
          p("Davon abgesehen sind natürlich sämtliche zusätzliche Daten ebenfalls möglicherweise von Interesse."),
          p("Vielen Dank an alle Mithelfenden!"),
        ),
      ),
    ),

  ) %>% renderTags()
})


plotly_default_config <- function(p) {
  p %>%
    config(locale = "de") %>%
    config(displaylogo = FALSE) %>%
    config(displayModeBar = TRUE) %>%
    config(modeBarButtons = list(list("toImage"))) %>%
    config(toImageButtonOptions = list(scale = 2)) %>%
    layout(yaxis = list(fixedrange = TRUE, rangemode = "tozero")) %>%
    layout(dragmode = FALSE) %>%
    layout(legend = list(bgcolor = "#ffffffaa", orientation = "h")) %>% # legend below plot
    identity()
}

plotly_time_range <- function(p) {
  p %>%
    layout(hovermode = "x") %>%
    layout(xaxis = list(fixedrange = TRUE, range = c(min(hgv$schuljahresbeginn)-1, max(hgv$schuljahresbeginn)+1))) %>%
    identity()
}

plotly_hide_axis_titles <- function(p) {
  return(
    p %>%
      layout(xaxis = list(title = list(standoff = 0, font = list(size = 1)))) %>%
      layout(yaxis = list(title = list(standoff = 0, font = list(size = 1)))) %>%
      layout(margin = list(l = 0, pad = 0, b = 30)) %>%
      identity()
  )
}

server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {

      output$plotTotal <- renderPlotly({
        p <- plot_ly(data = hgv, x = ~schuljahresbeginn) %>%
          add_trace(y = ~schueler, name = "Schüler:innen", type = "scatter", mode = "lines+markers", text = ~paste0(schuljahresbeginn, "/", schuljahresbeginn+1), hovertemplate = "%{y} Schüler:innen,\nSchuljahr %{text}<extra></extra>") %>%
          identity()

        if (input$plotTotalTextSwitch == "comments") {
          p <- p %>%
            add_annotations(data = hgv %>% filter(!is.na(kommentar)), x = ~schuljahresbeginn, y = 30, text = ~paste0(schuljahresbeginn, ": ", kommentar), textangle = -90, xanchor = "center", yanchor = "bottom", showarrow = FALSE) %>%
            identity()
        } else if (input$plotTotalTextSwitch == "schulleiter") {
          p <- p %>%
            add_annotations(data = schulleiter, x = ~((anfang+ende)/2), y = 30, text = ~schulleiter, textangle = -90, xanchor = "center", yanchor = "bottom", showarrow = FALSE) %>%
            add_segments(data = schulleiter, x = ~anfang, xend = ~anfang, y = 0, yend = 2000, color = I("gray"), line = list(dash = "dot"), showlegend = FALSE, hoverinfo = "skip") %>%
            identity()
        }

        p %>%
          plotly_default_config() %>%
          plotly_time_range() %>%
          layout(yaxis = list(title = "Schüler:innen", tickformat = ",d")) %>%
          layout(xaxis = list(title = "schuljahresbeginn")) %>%
          plotly_build()
      })

      output$plotNachGeschlecht <- renderPlotly({
        if (input$plotNachGeschlechtSwitch == "absolute") {
          plot_ly(data = hgv, x = ~schuljahresbeginn) %>%
            add_trace(y = ~schuelerMaennlich, name = "Schüler", type = "scatter", mode = "lines+markers", color = I("#1fc3aa"), text = ~schuelerMaennlich/(schuelerMaennlich+schuelerWeiblich), hovertemplate = "%{y} Schüler (%{text:.1%}),<extra></extra>") %>%
            add_trace(y = ~schuelerWeiblich, name = "Schülerinnen", type = "scatter", mode = "lines+markers", color = I("#8624f5"), text = ~schuelerWeiblich/(schuelerMaennlich+schuelerWeiblich), hovertemplate = "%{y} Schülerinnen (%{text:.1%}),<extra></extra>") %>%
            plotly_default_config() %>%
            plotly_time_range() %>%
            layout(yaxis = list(title = "Schüler:innen", tickformat = ",d")) %>%
            layout(xaxis = list(title = "")) %>%
            layout(hovermode = "x unified") %>%
            plotly_build()
        } else {
          plot_ly(data = hgv, x = ~schuljahresbeginn) %>%
            add_trace(y = ~schuelerMaennlich/(schuelerMaennlich+schuelerWeiblich), name = "Anteil männlich", type = "scatter", mode = "lines+markers", color = I("#1fc3aa"), text = ~paste0(schuelerMaennlich, " von ", (schuelerMaennlich+schuelerWeiblich)), hovertemplate = "%{y:.1%} männlich (%{text}),<extra></extra>") %>%
            add_trace(y = ~schuelerWeiblich/(schuelerMaennlich+schuelerWeiblich), name = "Anteil weiblich", type = "scatter", mode = "lines+markers", color = I("#8624f5"), text = ~paste0(schuelerWeiblich, " von ", (schuelerMaennlich+schuelerWeiblich)), hovertemplate = "%{y:.1%} weiblich (%{text}),<extra></extra>") %>%
            plotly_default_config() %>%
            plotly_time_range() %>%
            layout(yaxis = list(title = "Anteil an allen Schüler:innen", range = c(0.3, 0.7), tickformat = ".0%", hoverformat = ".0%")) %>%
            layout(xaxis = list(title = "")) %>%
            layout(hovermode = "x unified") %>%
            plotly_build()
        }
      })

    }
  )
}
