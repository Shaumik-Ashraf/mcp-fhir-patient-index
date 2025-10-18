# MCP FHIR Patient Index

[![CI](https://github.com/Shaumik-Ashraf/mcp-fhir-patient-index/actions/workflows/ci.yml/badge.svg)](https://github.com/Shaumik-Ashraf/mcp-fhir-patient-index/actions/workflows/ci.yml)

> ⚠️  Development in progress

A [master patient index](https://en.wikipedia.org/wiki/Enterprise_master_patient_index)
in Rails 8 with a conformant [FHIR](https://www.hl7.org/fhir/summary.html)
API and [Model Context Protocol (MCP)](https://modelcontextprotocol.io/about) for LLM
integration.

## Features

- Built-in MCP server
- Built-in minimalistic FHIR server
- Create, read, update, and destroy patients
- User friendly and customizable UI

## Constraints

- Supports US (en-speaking) patients only (no I18n)
- Supports FHIR R4 only


**This app has is not ready for real-patient data out of the box. For real-world use,
you must [regenerate credentials](https://guides.rubyonrails.org/security.html#custom-credentials),
and do a secure deployment with SOC-II compliance.** 

## Dependencies

- [Yarn](https://classic.yarnpkg.com/en/docs) 1.x
- [Ruby](https://www.ruby-lang.org/en/) 3.3
- [Docker](https://www.docker.com/) (optional)

## Quick Start

1. Ensure you have Docker running
2. If it's your first time, create a master key with `bin/rails credentials:edit`. Exit the editor
without any edits and the master key will be automatically created.
3. Build image:

```
docker build -t mcp_fhir_patient_index .
```

4. Run container:

```
docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name mcp_fhir_patient_index mcp_fhir_patient_index
```

## Developer Start

1. `yarn install`
2. `bundle`
3. `rails db:migrate`
4. `rails assets:precompile`
5. `rails server`

## Documentation

### Dev Tools

- `bundle exec rspec`: run tests
- `bundle exec rubocop`: run linter
- `./bin/brakeman`: run security scan

### Testing FHIR with Inferno

See [inferno-tests/README.md](inferno-tests/README.md)

### Testing MCP

I'm testing MCP with the official [inspector](https://github.com/modelcontextprotocol/inspector):

1. If you have npm installed run:

```
npx @modelcontextprotocol/inspector
```

OR if you have docker run:

```
docker run --rm --network host -p 6274:6274 -p 6277:6277 ghcr.io/modelcontextprotocol/inspector:latest
```

2. Open its web UI and use settings:

Transport Type: Streamable HTTP

URL: http://localhost:3000/mcp/v20250618

and press Connect.

### Tech Stack

Rails 8 with SQLite3, ESBuild, Bootstrap 5.3, and all other default options,
except JBuilder and ActionMailbox which were excluded.

## License

Copyright &copy; 2025 Shaumik Ashraf

This project is under the MIT License. You can view the license at
[LICENSE.txt](https://github.com/Shaumik-Ashraf/mcp-fhir-patient-index/blob/main/LICENSE.txt).

## Trademark Notice

HL7, FHIR and the FHIR [FLAME DESIGN] are the registered trademarks of Health
Level Seven International and their use does not constitute endorsement by HL7.
