require_relative 'lib/inferno_tests/version'

Gem::Specification.new do |spec|
  spec.name          = 'inferno_tests'
  spec.version       = InfernoTests::VERSION
  spec.authors       = ['Shaumik-Ashraf']
  # spec.email         = ['TODO']
  spec.summary       = 'Inferno Tests'
  spec.description   = <<~DESCRIPTION
    This Inferno test kit is specifically for testing the mcp-fhir-patient-index
    and is not intended to be released as a RubyGem.
  DESCRIPTION
  spec.homepage      = 'https://github.com/Shaumik-Ashraf/mcp-fhir-patient-index'
  spec.license       = 'Apache-2.0'
  spec.add_dependency 'inferno_core', '~> 1.0.6'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.3.7')
  spec.metadata['inferno_test_kit'] = 'true'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/Shaumik-Ashraf/mcp-fhir-patient-index'
  spec.files         = `[ -d .git ] && git ls-files -z lib config/presets LICENSE`.split("\x0")

  spec.require_paths = ['lib']

  spec.metadata['allowed_push_host'] = '' # disable pushing to RubyGems
end
