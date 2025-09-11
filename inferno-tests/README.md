# Inferno Tests for MCP FHIR Patient Index

This is an [Inferno](https://github.com/inferno-community/inferno-core) Test Kit
for FHIR integration testing.

## Running the Tests

If you are only using Docker you may
[run Inferno on Docker only](https://inferno-framework.github.io/docs/getting-started/#development-with-docker-only).

If you are developer I recommend using Inferno via Ruby:

1. From the top-level directory, start the Rails server: `rails server`
2. From the inferno-tests directory, setup Inferno: `bundle install`
3. `bundle exec inferno services start`
4. `bundle exec inferno start`
5. Go to <https://localhost:4567> to run Inferno tests
6. When finished, close Inferno with `SIGINT` (`Ctrl-C`) and `bundle exec inferno services stop`.

## Instructions for Developing Your Test Kit

Refer to the Inferno documentation for information about [setting up
your development environment and running your Test Kit](https://inferno-framework.github.io/docs/getting-started/).

More information about what is included in this repository can be
[found here](https://inferno-framework.github.io/docs/getting-started/repo-layout-and-organization.html).

## Documentation

- [Inferno documentation](https://inferno-framework.github.io/docs/)
- [Ruby API documentation](https://inferno-framework.github.io/inferno-core/docs/)
- [JSON API documentation](https://inferno-framework.github.io/inferno-core/api-docs/)

## Example Inferno Test Kits

A list of all Test Kits registered with the Inferno Team can be found on the [Test Kit Registry](https://inferno-framework.github.io/community/test-kits.html) page.

## License

Copyright 2025 Shaumik Ashraf

This folder is bundled under the [mcp-fhir-patient-index](https://github.com/Shaumik-Ashraf/mcp-fhir-patient-index)
project and its [License](https://github.com/Shaumik-Ashraf/mcp-fhir-patient-index/blob/main/LICENSE.txt).

## Trademark Notice

HL7, FHIR and the FHIR [FLAME DESIGN] are the registered trademarks of Health
Level Seven International and their use does not constitute endorsement by HL7.
