require_relative 'version'

module InfernoTests
  class Metadata < Inferno::TestKit
    # must come first due to class run-time order
    def self.readme
      @@readme ||= File.read(File.expand_path( '../../README.md', __dir__))
    end

    def self.modified_readme
      readme.sub("# #{title}", "## Inferno is running successfully!\n\nPress the button to get started.")
    end

    id :inferno_tests
    title 'Inferno Tests for MCP FHIR Patient Index'
    description <<~DESCRIPTION
      #{modified_readme}
    DESCRIPTION

    suite_ids [:inferno_tests]
    tags [] # E.g., ['SMART App Launch', 'US Core']
    last_updated LAST_UPDATED
    version VERSION
    maturity 'Low'
    authors ['Shaumik Ashraf']
    repo 'https://github.com/Shaumik-Ashraf/mcp-fhir-patient-index'
  end
end
