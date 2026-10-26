# Pre-course survey of gitklar for AI Retreat participants (participant org gitklar-airetreat).
# Built after agentsforsci-dev/pre-course-survey.

library(surveydown)

# Database setup --------------------------------------------------------------
#
# The survey runs in preview mode (survey.qmd YAML, `mode: preview`), so
# answers go to preview_data.csv and no database is used. For real answers:
# create the Supabase project of Lars Schöbitz GmbH (Zurich), run
# sd_db_config() once with table "gitklar_airetreat_2026_10", and set
# `mode: database`. Use the SESSION pooler (port 5432), not the transaction
# pooler (6543), see the agentsforsci README.

Sys.setenv(PGSSLMODE = "require")

# sd_db_connect() reads .env and connects whatever the mode is. In preview
# mode, skip the connection, so local test runs never touch the database.
survey_yaml <- local({
  lines <- readLines("survey.qmd", warn = FALSE)
  ends  <- which(lines == "---")
  yaml::yaml.load(paste(lines[(ends[1] + 1):(ends[2] - 1)], collapse = "\n"))
})
survey_mode <- survey_yaml$`survey-settings`$mode

db <- if (identical(survey_mode, "preview")) {
  NULL
} else {
  sd_db_connect(gssencmode = "disable")
}

ui <- sd_ui()

server <- function(input, output, session) {
  # Text fields shown only for the answers they belong to
  sd_show_if(
    sd_value("os") == "other" ~ "os_other",
    "other" %in% sd_value("ai_tools") ~ "ai_tools_other",
    "other" %in% sd_value("retreat_tools") ~ "retreat_tools_other",
    "other" %in% sd_value("writing_tools") ~ "writing_tools_other",
    "other" %in% sd_value("todo_place") ~ "todo_place_other",
    sd_value("second_brain") %in% c("yes", "building") ~ "second_brain_tool",
    "chat" %in% sd_value("ai_levels") ~ "ai_level_chat_tool",
    "context" %in% sd_value("ai_levels") ~ "ai_level_context_tool",
    "connectors" %in% sd_value("ai_levels") ~ "ai_level_connectors_tool",
    "skills" %in% sd_value("ai_levels") ~ "ai_level_skills_tool",
    "routines" %in% sd_value("ai_levels") ~ "ai_level_routines_tool",
    sd_value("github_account") == "yes" ~ "github_username"
  )

  # Checks when the participant clicks Next
  sd_stop_if(
    !grepl(
      "^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$",
      trimws(sd_value("email", as_numeric = FALSE))
    ) ~
      "Bitte gib eine gültige E-Mail-Adresse ein.",

    isTRUE(sd_value("github_account") == "yes") &
      !grepl(
        "^[A-Za-z0-9-]{1,39}$",
        trimws(sd_value("github_username", as_numeric = FALSE))
      ) ~
      "Bitte gib deinen GitHub-Benutzernamen ohne das @ ein. Er besteht aus Buchstaben, Ziffern und Bindestrichen.",

    "none" %in% sd_value("ai_tools") & length(sd_value("ai_tools")) > 1 ~
      "KI-Werkzeuge: Bitte wähle entweder «Keine» oder die Werkzeuge, die du nutzt.",
    "none" %in% sd_value("retreat_tools") & length(sd_value("retreat_tools")) > 1 ~
      "Werkzeuge aus dem AI Retreat: Bitte wähle entweder «Keines davon» oder die Werkzeuge, die du installiert hast.",
    "none" %in% sd_value("ai_levels") & length(sd_value("ai_levels")) > 1 ~
      "Stufen: Bitte wähle entweder «Keine davon» oder die Stufen, die du nutzt.",
    "none" %in% sd_value("slots") & length(sd_value("slots")) > 1 ~
      "Termine: Bitte wähle entweder «Keiner dieser Termine passt» oder die Termine, die dir passen.",

    # Two workshops, so at least two slots. The guard on length >= 1 keeps
    # this check quiet on the pages before the slot question.
    length(sd_value("slots")) == 1 & !("none" %in% sd_value("slots")) ~
      "Termine: Es gibt zwei Workshops. Bitte kreuze mindestens zwei Termine an, die für dich gehen.",

    # "Keiner passt" alone needs the note on other times. Keep sd_value()
    # calls inline: the same check through a helper function never fired.
    length(sd_value("slots")) == 1 & "none" %in% sd_value("slots") &
      !nzchar(paste(trimws(sd_value("slots_note", as_numeric = FALSE)), collapse = "")) ~
      "Termine: Wenn keiner der Termine passt, schreib bitte ins Feld darunter, wann es dir geht."
  )

  sd_server(db = db)
}

shiny::shinyApp(ui = ui, server = server)
