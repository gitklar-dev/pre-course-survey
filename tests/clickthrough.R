# Headless click-through of the survey with chromote.
#
# Start the app first, in preview mode, from the project folder:
#   QUARTO_PATH=/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto \
#     Rscript -e 'shiny::runApp("app.R", port = 8765, launch.browser = FALSE)'
# Open one throwaway session after each change to survey.qmd (re-parse
# gotcha), then run:
#   Rscript tests/clickthrough.R [url]
#
# Checks: every page loads without duplicate ids, the conditional text
# fields appear only for their answers and block Next only while visible,
# the email and username checks refuse bad input, and one full response
# reaches the end page. Test answers use the address test@example.org.

library(chromote)

url <- commandArgs(TRUE)[1]
if (is.na(url)) url <- "http://127.0.0.1:8765"

b <- ChromoteSession$new()
js <- function(x) b$Runtime$evaluate(x, returnByValue = TRUE)$result$value
fails <- character(0)
check <- function(ok, what) {
  cat(if (isTRUE(ok)) "PASS " else "FAIL ", what, "\n", sep = "")
  if (!isTRUE(ok)) fails <<- c(fails, what)
}

visible <- function(sel) {
  isTRUE(js(sprintf(
    "(function(){var e=document.querySelector('%s');return !!(e && e.offsetParent!==null);})()",
    sel
  )))
}
wait_for <- function(sel, timeout = 20) {
  t0 <- Sys.time()
  while (difftime(Sys.time(), t0, units = "secs") < timeout) {
    if (visible(sel)) return(TRUE)
    Sys.sleep(0.25)
  }
  FALSE
}
set_text <- function(id, value) {
  js(sprintf(
    "$('#%s').val(%s).trigger('input').trigger('change');",
    id, jsonlite::toJSON(value, auto_unbox = TRUE)
  ))
  Sys.sleep(0.4)
}
pick <- function(name, value) {
  js(sprintf(
    "document.querySelector('input[name=\"%s\"][value=\"%s\"]').click();",
    name, value
  ))
  Sys.sleep(0.4)
}
shown <- function(id) visible(sprintf("#container-%s", id))
no_duplicate_ids <- function() {
  d <- js("(function(){var s={},d=[];document.querySelectorAll('[id]').forEach(function(e){if(s[e.id])d.push(e.id);s[e.id]=1});return d.join(',');})()")
  identical(d, "")
}
# Click Next and report whether the next page appeared
go_next <- function(page, next_sel, timeout = 20) {
  js(sprintf("document.getElementById('%s_next').click();", page))
  wait_for(next_sel, timeout)
}
# Click Next and report whether the page stayed (Next refused)
blocked <- function(page) {
  js(sprintf("document.getElementById('%s_next').click();", page))
  Sys.sleep(2)
  visible(sprintf("#%s_next", page))
}

invisible(b$Page$navigate(url))
check(wait_for("#start_next", 30), "start page loads")
check(no_duplicate_ids(), "start: no duplicate ids")
check(!grepl("Duplicate IDs", js("document.body.innerText")), "start: no duplicate id error")

# Page ueber_dich
check(go_next("start", "#ueber_dich_next"), "start -> ueber_dich")
check(no_duplicate_ids(), "ueber_dich: no duplicate ids")
check(!shown("os_other"), "os_other hidden at first")
set_text("email", "not-an-email")
pick("os", "other")
check(shown("os_other"), "os_other shown for 'Ein anderes'")
check(blocked("ueber_dich"), "bad email and empty os_other block Next")
set_text("email", "test@example.org")
check(blocked("ueber_dich"), "empty os_other blocks Next")
pick("os", "macos")
check(!shown("os_other"), "os_other hidden again for macOS")
check(go_next("ueber_dich", "#werkzeuge_next"), "ueber_dich -> werkzeuge")

# Page werkzeuge
check(no_duplicate_ids(), "werkzeuge: no duplicate ids")
pick("ai_tools", "claude")
pick("ai_tools", "none")
pick("writing_tools", "obsidian")
pick("todo_place", "paper")
pick("second_brain", "no")
check(blocked("werkzeuge"), "'Keine' plus a tool blocks Next")
pick("ai_tools", "none")
pick("ai_tools", "other")
check(shown("ai_tools_other"), "ai_tools_other shown for 'Andere'")
check(blocked("werkzeuge"), "empty ai_tools_other blocks Next")
set_text("ai_tools_other", "Mistral Le Chat Pro")
check(!shown("second_brain_tool"), "second_brain_tool hidden for 'Nein'")
pick("second_brain", "building")
check(shown("second_brain_tool"), "second_brain_tool shown for 'baue gerade auf'")
check(go_next("werkzeuge", "#ki_stufen_next"), "werkzeuge -> ki_stufen (second_brain_tool optional)")

# Page ki_stufen
check(no_duplicate_ids(), "ki_stufen: no duplicate ids")
lv <- c("chat", "context", "connectors", "skills", "routines")
check(!any(vapply(sprintf("ai_level_%s_tool", lv), shown, logical(1))), "all level tool fields hidden at first")
pick("ai_levels", "chat")
pick("ai_levels", "skills")
check(shown("ai_level_chat_tool") && shown("ai_level_skills_tool"), "tool fields shown for chosen levels")
check(!shown("ai_level_context_tool") && !shown("ai_level_routines_tool"), "tool fields hidden for other levels")
check(blocked("ki_stufen"), "empty tool fields block Next")
set_text("ai_level_chat_tool", "Claude")
set_text("ai_level_skills_tool", "Claude Skills")
check(go_next("ki_stufen", "#erfahrung_next"), "ki_stufen -> erfahrung")

# Page erfahrung
check(no_duplicate_ids(), "erfahrung: no duplicate ids")
pick("prog_general", "few_lines")
pick("cli_usage", "occasional")
pick("git_experience", "never")
check(!shown("github_username"), "github_username hidden at first")
pick("github_account", "yes")
check(shown("github_username"), "github_username shown for 'Ja'")
set_text("github_username", "@bad name")
check(blocked("erfahrung"), "bad GitHub username blocks Next")
set_text("github_username", "octocat")
check(go_next("erfahrung", "#ziele_next"), "erfahrung -> ziele")

# Page ziele
check(no_duplicate_ids(), "ziele: no duplicate ids")
set_text("learning_goals", "Testantwort: Git verstehen")
set_text("use_case", "Testantwort: eigene Website")
check(go_next("ziele", "#termin_next"), "ziele -> termin (retreat_work optional)")

# Page termin
check(no_duplicate_ids(), "termin: no duplicate ids")
pick("slots", "2026-11-17_2000")
pick("slots", "2026-12-01_2000")
pick("slots", "none")
check(blocked("termin"), "'Keiner passt' plus a slot blocks Next")
pick("slots", "none")
check(go_next("termin", "#einwilligung_next"), "termin -> einwilligung (slots_note optional)")

# Page einwilligung
check(no_duplicate_ids(), "einwilligung: no duplicate ids")
check(blocked("einwilligung"), "missing consent blocks Next")
pick("consent", "yes")
js("document.getElementById('einwilligung_next').click();")
t0 <- Sys.time()
reached <- FALSE
while (difftime(Sys.time(), t0, units = "secs") < 20) {
  if (grepl("Deine Antworten sind gespeichert", js("document.body.innerText"))) { reached <- TRUE; break }
  Sys.sleep(0.25)
}
check(reached, "einwilligung -> ende")

# Previous answers restore after going back is not tested here.
b$close()

if (file.exists("preview_data.csv")) {
  d <- utils::read.csv("preview_data.csv")
  row <- d[d$email %in% "test@example.org", , drop = FALSE]
  check(nrow(row) >= 1, "preview_data.csv holds the test response")
  if (nrow(row) >= 1) {
    r <- row[nrow(row), ]
    check(identical(as.character(r$consent), "yes"), "stored consent is yes")
    check(identical(as.character(r$github_username), "octocat"), "stored github_username")
    check(grepl("2026-11-17_2000", r$slots) && grepl("2026-12-01_2000", r$slots), "both ticked slots stored")
    check(!any(c("ip_address", "browser") %in% names(d)), "no IP address or browser stored")
  }
} else {
  check(FALSE, "preview_data.csv exists (run from the project folder)")
}

cat("\n", length(fails), " failure(s)\n", sep = "")
quit(status = if (length(fails)) 1 else 0)
