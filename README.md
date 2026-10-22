# Pre-course survey: gitklar

Participants of AI Retreats join the organisation `gitklar-airetreat`, which can hold participants of several retreats.

This is the pre-course survey of gitklar, a Git and GitHub course offered by Lars Schöbitz GmbH. It is built with [surveydown](https://surveydown.org) (R, Quarto and Shiny) after the pre-course survey in `agentsforsci-dev/pre-course-survey`. Answers are meant to go to a Supabase database in Zurich, and the survey is meant to run on Posit Connect Cloud. For now the survey runs in preview mode only, until the database is set up (see below).

## What the survey asks

The survey is in German, informal (du), and takes about 10 minutes. It has 15 required questions on seven pages and 3 optional ones (`second_brain_tool`, `retreat_work`, `slots_note`). Follow-up text fields (the "Andere" fields, one tool field per chosen AI level, the GitHub username) appear only for some answers and are required only while they are shown.

| Page | Question id | Question | Source |
|---|---|---|---|
| ueber_dich | `email` | E-Mail-Adresse | ds4owd XLSForm `email` |
| ueber_dich | `os`, `os_other` | Betriebssystem des Kurs-Laptops | agentsforsci `os`, plus "Ich weiss es nicht" |
| werkzeuge | `ai_tools`, `ai_tools_other` | KI-Werkzeuge in Gebrauch | agentsforsci `ai_tools` (from ds4owd `llm_platforms`), shortened, plus Make/n8n/Zapier |
| werkzeuge | `writing_tools`, `writing_tools_other` | Werkzeuge für Texte und Notizen | new, replaces ds4owd `ide_used` and `note_taking_tool_specify` |
| werkzeuge | `todo_place`, `todo_place_other` | Wo die TODOs heute stehen | new (journal 2026-10-19) |
| werkzeuge | `second_brain`, `second_brain_tool` (optional) | Zweites Gehirn | new (journal 2026-10-19) |
| ki_stufen | `ai_levels` | Welche der fünf Stufen der KI-Nutzung | new, from the AI Retreat deep-dive of 16 October 2026 |
| ki_stufen | `ai_level_<stufe>_tool` (5 fields) | Werkzeug je gewählter Stufe | new |
| erfahrung | `prog_general` | Erfahrung mit Programmieren | ds4owd `prog_general` |
| erfahrung | `cli_usage` | Nutzung des Terminals | ds4owd and agentsforsci `cli_usage`, reworded |
| erfahrung | `git_experience` | Erfahrung mit Git | ds4owd `git_experience` |
| erfahrung | `github_account` | GitHub-Konto vorhanden | new |
| erfahrung | `github_username` | GitHub-Benutzername, only if there is an account | ds4owd and agentsforsci `github_username` |
| ziele | `retreat_work` (optional) | Was am AI Retreat gemacht und gelernt, Miro-Texte willkommen | new |
| ziele | `learning_goals` | Was du nach dem Kurs wissen oder können willst | ds4owd and agentsforsci `learning_goals` |
| ziele | `use_case` | Eigenes Projekt für den Kurs | new, loosely after ds4owd `data_availability` |
| termin | `slots`, `slots_note` (required only with "Keiner passt") | Mindestens zwei passende Termine für die zwei Workshops | new |
| einwilligung | `consent` | Einwilligung | agentsforsci `consent` and ds4owd `data_privacy`, adapted |

No browser details and no IP addresses are stored (`capture-metadata: false`).

## Open points before the survey goes out

- **Course title.** `survey.qmd` uses the working title "Git und GitHub: Einführungskurs". Three options are open:
  1. Never Commit Alone: Git und GitHub mit KI, ohne KI und mit anderen
  2. Selbst entscheiden, offen arbeiten: Git und GitHub für deine Projekte
  3. Gemeinsam nachvollziehbar: Git und GitHub mit und ohne KI
- **Contact address.** `lars@lse.de` in the welcome text and the consent is a placeholder until Lars confirms it.
- **Time slots (placeholders).** The course has two online sessions of two hours. Participants tick at least two slots that work for them (enforced in `app.R`), or only "Keiner dieser Termine passt" plus a note on other times. Lars picks the two slots that suit most people. Both sessions are over before 11 December 2026. All slots are Monday to Thursday, 20:00 to 22:00. They avoid RDC (19 and 20 November), the EnhanceR symposium (30 November) and SwissRN in Bellinzona (10 December). Lars confirms them:
  - Dienstag, 17. November 2026
  - Montag, 23. November 2026
  - Donnerstag, 26. November 2026
  - Dienstag, 1. Dezember 2026
  - Donnerstag, 3. Dezember 2026
  - Mittwoch, 9. Dezember 2026
- **Database and hosting.** The survey stays in `mode: preview` until the steps below are done.

## Run the survey locally

Quarto is not on the PATH of this Mac, so point surveydown at the RStudio copy:

```sh
QUARTO_PATH=/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto \
  Rscript -e 'shiny::runApp("app.R", port = 8765, launch.browser = FALSE)'
```

Test answers go to `preview_data.csv`, which is git-ignored. In preview mode `app.R` does not call `sd_db_connect()`, so a local run never touches the database, even when `.env` holds real credentials. surveydown re-renders the survey only when `survey.qmd`, a YAML file or `app.R` changes. After an edit to `custom.scss` alone, touch `survey.qmd`.

After any change to `survey.qmd`, open one throwaway session first. The session that re-parses the file does not restore answers on Previous.

## Test

With the app running, from this folder:

```sh
Rscript tests/clickthrough.R
```

The script uses chromote (headless Chrome). It checks that every page loads without duplicate ids. It also checks that the follow-up fields appear only for their answers and block Next only while visible. Bad email addresses, bad GitHub usernames and "none" combined with other answers are refused. One full response reaches the end page and lands in `preview_data.csv` without IP address or browser details.

## Database and deployment: steps for Lars

These steps need Lars's own accounts. Nothing here has been created yet.

1. **Supabase project.** Create a new Supabase project for Lars Schöbitz GmbH in the region Central EU (Zurich), `eu-central-2`. Keep the database password.
2. **Connection values.** In the project, open Connect, then the Direct tab, and copy the values of the **session pooler** (pooler host, port **5432**). Do not use the transaction pooler (port 6543), it fails with RPostgres.
3. **`.env` file.** In this folder, run `surveydown::sd_db_config()` and enter the values, or write `.env` by hand with these keys:

   ```
   SD_HOST=<session pooler host>
   SD_PORT=5432
   SD_DBNAME=postgres
   SD_USER=<pooler user, postgres.<project ref>>
   SD_PASSWORD=<database password>
   SD_TABLE=gitklar_airetreat_2026_10
   ```

   `.env` is git-ignored and never leaves the machine. `app.R` sets `PGSSLMODE=require` itself, so every connection uses TLS, also on Connect Cloud. You can add `PGSSLMODE=require` to `.env` as well, but the deploy script only ships the six `SD_*` values.
4. **Database mode.** Set `mode: database` in the `survey.qmd` YAML header.
5. **Test response.** Run the app locally once and send one full test response. surveydown creates the table, adds the columns on first use and turns on row level security. Delete the test row in Supabase afterwards.
6. **Connect Cloud login.** Log in once with the GmbH account in your own R console: `rsconnect::connectCloudUser()`.
7. **Deploy.** From a terminal, with Quarto exported:

   ```sh
   export QUARTO_PATH=/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto
   ~/Documents/gitrepos/context-agentsforsci/surveydown-skill/deploy-posit-cloud/deploy.sh \
     --title "Git und GitHub: Umfrage vor dem Kurs" \
     --slug gitklar-airetreat-umfrage \
     --dir ~/Documents/gitrepos/context-gitklar/gh-org-gitklar-dev/pre-course-survey
   ```

   Without `QUARTO_PATH` the script ships no `_survey/` cache and gives no message. The script sends the `SD_*` values as content secrets and sets access to public. If the GmbH account is not your only Connect Cloud account, add `--account <name>`. A second run updates the app in place.
8. **Live check.** Open the live address in a fresh browser window, answer once, and delete that row in Supabase.

## Responses never enter git

Responses are personal data. `.env`, `preview_data.csv` and `local_data.csv` are git-ignored. Exports belong in a folder outside any repository.

## License

CC-BY-4.0. Adapted from the agentsforsci and ds4owd pre-course surveys.
