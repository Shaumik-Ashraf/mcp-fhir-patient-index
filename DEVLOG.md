# DEVLOG

Developer log and backlog of tasks.

- [x] Install FactoryBot and RSpec
- [x] Customize Bootstrap via SCSS pipeline
- [x] Draft initial Patient schema
- [x] Implement Patient index view and read
- [x] Implement Patient create
- [x] Implement Patient edit and update
- [~] Implement Patient snapshots and versioning
  + snapshots and versioning implemented
  + needs undo/version recovery
- [~] Implement Patient hard-destroy and soft-delete
  + soft delete implemented
  + needs recovery and hard delete
- [x] Implement skeleton FHIR server
- [x] Implement FHIR patient read API
- [x] Implement FHIR Capability Statement
- [x] Add Inferno end-to-end tests
- [x] Implement skeleton MCP server
- [x] Implement MCP resource server
  + improve the info endpoint
  + refactor patient record resource template
  + TODO: test resources
- [~] Implement MCP tools server
  + TODO: test all tools
- [x] Implement FHIR Log that showcases fhir queries
- [x] Implement MCP Log with showcases llm integration
- [x] Implement some client-side LLM or test w/ some MCP client (Use LM Studio)
- [x] Implement settings to customize UI
- [x] Make realistically messy patient identity data generator
- [ ] Factorize "messy data generator" so its easily modable
- [x] Implement patient data grid
- [x] Implement patient linking
- [x] Make patient diff page for comparing records and manual stewardship
- [x] Implement patient matching engine that automates matches
- [x] Implement FHIR `$match`
- [ ] e2e tests (Selenium or otherwise)
- [ ] Rename the MCP server to `mpi:`
- [ ] OAuth 2.0

## Notes

- `~` means partially complete.
