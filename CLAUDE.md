# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**MCP FHIR Patient Index** is a Rails 8 application implementing a Master Patient Index (MPI) with:
- A FHIR R4 conformant REST API for patient data
- Model Context Protocol (MCP) server for LLM integration
- Web UI for patient CRUD and record linking/deduplication
- Patient identity matching and record linkage workflow

Tech stack: Ruby 3.3.7, Rails 8.0, SQLite3, Hotwire (Stimulus + Turbo), Bootstrap 5.3, ESBuild, Sass.

## Commands

### Setup
```bash
yarn install && bundle
rails db:migrate
rails assets:precompile
```

### Development
```bash
# Start all services (web + JS/CSS watchers)
bin/dev   # uses Procfile.dev

# Or individually:
rails server
yarn build --watch
yarn watch:css
```

### Testing
```bash
bundle exec rspec                          # all tests
bundle exec rspec spec/models/             # models only
bundle exec rspec spec/path/to/file_spec.rb  # single file
bundle exec rspec spec/path/to/file_spec.rb:42  # single example
```

### Linting & Security
```bash
bundle exec rubocop                        # Ruby linter (Rails Omakase style)
bundle exec rubocop -a                     # auto-fix safe violations
./bin/brakeman                             # security scan
yarn herb:lint                             # ERB/view linting
yarn herb:format                           # format views
```

### Frontend builds
```bash
yarn build                                 # bundle JS
yarn build:css                             # compile Sass + autoprefixer
```

### FHIR Conformance Testing (Inferno)
```bash
cd inferno-tests
bundle install
bundle exec inferno services start
bundle exec inferno start                  # https://localhost:4567
bundle exec inferno services stop
```

### MCP Inspector
```bash
npx @modelcontextprotocol/inspector
# Connect to: http://localhost:3000/mcp/v20250618
```

## Architecture

### URL Namespaces
- `/fhir/r4/` — FHIR R4 API (metadata, Patient read/search)
- `/mcp/v20250618/` — MCP HTTP streamable transport endpoint
- `/patients/` — Web UI patient CRUD
- `/patient_joins/` — Record linking workflow
- `/settings/` — Application settings

### Key Models
- **PatientRecord** (`app/models/patient_record.rb`) — Core model. Has `to_fhir()` for FHIR conversion, `to_text()` for LLM-friendly representation, `simulate_corruption()` for testing identity matching, and `linked_patient_records()` / `each_linked_record()` for bidirectional join traversal. Uses `active_snapshot` gem for versioning.
- **PatientJoin** (`app/models/patient_join.rb`) — Self-join table linking patient records. Qualifier `has_same_identity_as` is treated as bidirectional. Stored as directional but queried bidirectionally.
- **Setting** (`app/models/setting.rb`) — Key-value store. Access via `Setting[:key]` / `Setting[:key] = value`.

### MCP Server
`app/mcp/application_mcp.rb` — Module `ApplicationMCP` included in `app/controllers/mcp/v20250618/application_controller.rb`. Implements MCP protocol v2025-06-18. Exposes three resources:
- `master-patient-index://info` — server info
- `master-patient-index://all` — all patient records as text
- `master-patient-index://patient_record/{id}` — individual patient (resource template)

### FHIR API
`app/controllers/fhir/r4/` has `patients_controller.rb` (read + search returning FHIR Bundle) and `metadata_controller.rb` (CapabilityStatement). Patient resources are built from `PatientRecord#to_fhir()` using the `fhir_models` gem.

### Patient Linking Workflow
`PatientJoinsController` handles a multi-step flow: select patients → compare side-by-side → create link. Links are bidirectional logically but stored as directional rows. `PatientRecord` traverses both directions via `patient_joins` and `reverse_patient_joins` associations.

### Test Structure
- `spec/requests/` — Integration/request specs including `fhir/r4/` and `mcp/v20250618/` subdirs
- `factories/` — FactoryBot factories (note: top-level `factories/` dir, not `spec/factories/`)
- Rubocop-RSpec plugin active; ExampleLength, MultipleExpectations, and IndexedLet cops are disabled

## Constraints
- FHIR R4 only; English/US patients only
- MCP protocol version: v2025-06-18
- SQLite3 in all environments (dev, test, prod)
- Not production-ready: credentials need regeneration before real deployment
