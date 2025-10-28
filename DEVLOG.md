# DEVLOG

Developer log and backlog of tasks.

- [x] Install FactoryBot and RSpec
- [x] Customize Bootstrap via SCSS pipeline
- [x] Draft initial Patient schema
- [x] Implement Patient index view and read
- [x] Implement Patient create
- [~] Implement Patient edit and update
  + improve ui
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
- [ ] Implement MCP tools server
- [ ] Implement FHIR Log that showcases fhir queries
- [ ] Implement MCP Log with showcases llm integration
- [ ] Implement some client-side LLM or test w/ some MCP client
- [ ] Implement settings to customize UI
  + anonymous mode: hide ssns and other sensitive information
  + matching threshold
- [ ] Explain HIPAA vs SOC-II
- [x] Make realistically messy patient identity data generator
- [ ] Factorize "messy data generator" so its easily modable - would increase this app's value prop as an identity matching lab
- [ ] Implement patient data grid
- [~] Implement patient linking
  + patient join model is done, need to add ui **TODO**
- [ ] Make patient diff page for comparing records and manual stewardship
- [ ] Implement patient matching engine that automates matches
- [ ] Implement FHIR `$match`
- [ ] Implement MCP patient match tool
- [ ] Create docker compose for cleaner docker setup
- [ ] Better RSpec
- [ ] e2e tests (Selenium or otherwise)


## Notes

- `~` means partially complete
