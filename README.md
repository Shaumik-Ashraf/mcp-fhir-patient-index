# FHIR Patient Index

A [master patient index](https://en.wikipedia.org/wiki/Enterprise_master_patient_index)
in Rails 8 with a conformant FHIR API.

## Features

- Built-in [MCP](https://modelcontextprotocol.io/about) server for LLM integration
- Built-in minimalistic [FHIR](https://www.hl7.org/fhir/summary.html) server
- Create, read, update, and destroy patients
- User friendly and customizable UI

**This app has is not ready for real-patient data out of the box. For real-world use,
you must [regenerate credentials](https://guides.rubyonrails.org/security.html#custom-credentials),
and do a secure deployment with SOC-II compliance.** 

## Dependencies

For running:

- [Docker](https://www.docker.com/)

For developing:

- [Yarn](https://classic.yarnpkg.com/en/docs) 1.x
- [Ruby](https://www.ruby-lang.org/en/) 3.3

## Quick Start

**wip**

1. Ensure you have Docker running
2. `docker compose up`

## Developer Start

1. `yarn install`
2. `bundle`
3. `rails db:migrate`
4. `rails server`

## Documentation

### Dev Tools

- `rails t`: run tests
- `bundle exec rubocop`: run linter
- `./bin/brakeman`: run security scan

### Tech Stack

Rails 8 with SQLite3, ESBuild, Bootstrap 5.3. Action Mailbox, and Turbo.
JBuilder and ActionMailbox were excluded.
