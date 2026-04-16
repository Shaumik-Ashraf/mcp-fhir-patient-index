# @example
#   class MyController < ApplicationController
#     include ApplicationMCP
#     def index
#       render json: mcp_streamable_http.handle_json(request.body.read)
#     end
#   end
#
# @example
#   class CLI
#     include ApplicationMCP
#     def run
#       mcp_stdio.open
#     end
#   end
module ApplicationMCP
  SCHEME = "master-patient-index"
  NAME = Rails.application.name.underscore
  TITLE = Rails.application.name.humanize
  INSTRUCTIONS = <<~EOT
    See https://github.com/Shaumik-Ashraf/mcp-fhir-patient-index/README.md
  EOT

  @tools = []
  @prompts = []
  @resources = [] # Array<ResourceWrapper>
  @resource_templates = [] # Array<ResourceTemplateWrapper>

  # @param [String] name
  # @param [String] description
  # @param [Hash] input_schema - JSON Schema Draft 4 { properties: {}, required: [] }
  # @param [MCP::Tool::Annotations, nil] annotations
  # @param [Proc] &block - tool implementation block
  def define_mcp_tool(name, description, input_schema, annotations = nil, &block)
    @tools ||= []
    @tools << MCP::Tool.define(
      name: name,
      description: description,
      input_schema: input_schema,
      annotations: annotations,
      &block
    )
  end

  # @param [String] endpoint - the mcp base name from which url and name are derived
  # @param [String] mime_type
  # @param [String] title - this property is in DRAFT in the MCP v20250618 spec
  # @param [String] description
  # @param [#call] callable - lambda that returns an array of hash with uri, mimeType, and text
  def define_resource(endpoint, mime_type, title, description, callable)
    @resources ||= []
    @resources << ResourceWrapper.new(endpoint, mime_type, title, description, callable)
  end

  # @private
  class ResourceWrapper
    extend Forwardable

    attr_reader :mcp_resource
    attr_reader :callable

    def_delegators :@mcp_resource, :uri, :name, :title, :description, :mime_type

    def initialize(endpoint, mime_type, title, description, callable)
      @mcp_resource = MCP::Resource.new(
        uri: "#{SCHEME}://#{endpoint}",
        name: endpoint.to_s.underscore,
        title:,
        description:,
        mime_type:
      )
      @callable = callable
    end

    def match?(params)
      self.uri == params[:uri]
    end

    def call
      [ {
         uri: uri,
         mimeType: mime_type,
         text: @callable.call
       } ]
    end
  end

  # @private
  class ResourceTemplateWrapper
    extend Forwardable

    ID_REGEX = "[A-Za-z0-9_-]+"

    attr_reader :klass

    def initialize(klass)
      @klass = klass
    end

    def mcp_resource_template
      @mcp_resource_template ||= MCP::ResourceTemplate.new(
        uri_template: resource_template_uri(klass),
        name: klass.to_s.underscore.singularize,
        title: klass.to_s.humanize,
        description: "#{klass.to_s.humanize} resource parameterized by id",
        mime_type: case klass
                   when ->(k) { k.instance_methods.include? :to_text }
                     "text/plain"
                   else
                     raise StandardError, "#{klass} does not respond to #to_text"
                   end
      )
    end

    def uri_regex
      resource_template_uri_regex(klass)
    end

    # TODO: A better DX would probably be replacing regex match with string starts with
    # and stipulate that all mcp endpoints must have different starting urls
    def match?(params)
      uri_regex.match? params[:uri]
    end

    # TODO: parameterize callable
    def callable
      Proc.new() { |params| klass.find_by!(uuid: File.basename(params[:uri]))&.to_text }
    end

    def call(params)
      [ {
         uri: params[:uri],
         mimeType: mcp_resource_template.mime_type,
         text: callable.call(params)
       } ]
    end

    private

    def resource_template_uri(klass)
      "#{resource_template_uri_prefix(klass)}/{id}"
    end

    def resource_template_uri_regex(klass)
      %r{#{Regexp.escape(resource_template_uri_prefix(klass))}/(#{ID_REGEX})}
    end

    def resource_template_uri_prefix(klass)
      "#{SCHEME}://#{klass.to_s.underscore.singularize}"
    end
  end

  # Treat an ActiveRecord as an MCP resource template searchable by id
  # @example
  #   load_application_records_as_resource_templates(Post, Comment)
  # @param [Array<Constants>] klasses
  def load_application_records_as_resource_templates(*klasses)
    @resource_templates ||= []
    klasses.each do |klass|
      @resource_templates << ResourceTemplateWrapper.new(klass)
    end
  end

  # Build server at run time
  # @return [MCP::Server]
  def server
    # TODO: app-specific logic is defined here, but this module could be made into
    # an abstracted MCP class
    define_resource "info", "text/plain", "Retrieve MCP Server Info", "...", (lambda do
      <<~EOT
        This is a master patient index server that supports model context
        protocol (MCP). It contains patient records of demographic information
        for retrieval, matching, and de-duplication.
      EOT
    end)

    define_resource "all", "text/plain", "Retrieve all Patient Records", "...", (lambda do
      text = PatientRecord.all.map(&:to_text).join("\n")
      AuditLog.create!(
        description: "LLM read all patient records",
        tags: { AuditLog::Tag::EVENT => AuditLog::Event::MCP_READ_ALL_PATIENTS, AuditLog::Tag::INTERFACE => AuditLog::Interface::MCP },
        encrypted_request: { uri: "#{SCHEME}://all" },
        encrypted_response: { record_count: PatientRecord.count }
      )
      text
    end)

    load_application_records_as_resource_templates(PatientRecord)

    define_mcp_tool(
      "create_patient",
      "Create a new patient record in the master patient index. All fields are optional.",
      {
        properties: {
          first_name:             { type: "string" },
          last_name:              { type: "string" },
          administrative_gender:  { type: "string", enum: %w[male female other unknown] },
          birth_date:             { type: "string", description: "ISO 8601 date, e.g. 1990-01-15" },
          email:                  { type: "string" },
          phone_number:           { type: "string" },
          address_line1:          { type: "string" },
          address_line2:          { type: "string" },
          address_city:           { type: "string" },
          address_state:          { type: "string" },
          address_zip_code:       { type: "string" },
          social_security_number: { type: "string" },
          passport_number:        { type: "string" },
          drivers_license_number: { type: "string" }
        },
        required: []
      },
      { destructive_hint: true, idempotent_hint: false }
    ) do |server_context: nil, **params|
      patient = PatientRecord.new(params)
      patient.save!
      result_text = "Created patient #{patient.uuid}\n\n#{patient.to_text}"
      AuditLog.create!(
        description: "LLM created patient record",
        tags: { AuditLog::Tag::EVENT => AuditLog::Event::MCP_CREATE_PATIENT, AuditLog::Tag::INTERFACE => AuditLog::Interface::MCP },
        encrypted_request: params.to_h,
        encrypted_response: { uuid: patient.uuid }
      )
      MCP::Tool::Response.new([ { type: "text", text: result_text } ])
    end

    define_mcp_tool(
      "link_patients",
      "Link two patient records as having the same identity (has_same_identity_as). The link is bidirectional.",
      {
        properties: {
          patient_uuid_1: { type: "string", description: "UUID of the first patient record" },
          patient_uuid_2: { type: "string", description: "UUID of the second patient record" },
          notes:          { type: "string", description: "Optional notes about why these records were linked" }
        },
        required: %w[patient_uuid_1 patient_uuid_2]
      },
      { destructive_hint: true, idempotent_hint: false }
    ) do |patient_uuid_1:, patient_uuid_2:, notes: nil|
      patient1 = PatientRecord.find_by!(uuid: patient_uuid_1)
      patient2 = PatientRecord.find_by!(uuid: patient_uuid_2)
      PatientJoin.create!(
        from_patient_record: patient1,
        to_patient_record: patient2,
        qualifier: :has_same_identity_as,
        notes: notes
      )
      result_text = "Linked patients:\n- #{patient_uuid_1} (#{patient1.to_text.lines.first.chomp})\n- #{patient_uuid_2} (#{patient2.to_text.lines.first.chomp})"
      AuditLog.create!(
        description: "LLM linked patient records",
        tags: { AuditLog::Tag::EVENT => AuditLog::Event::MCP_LINK_PATIENT, AuditLog::Tag::INTERFACE => AuditLog::Interface::MCP },
        encrypted_request: { patient_uuid_1: patient_uuid_1, patient_uuid_2: patient_uuid_2, notes: notes },
        encrypted_response: { patient_uuid_1: patient_uuid_1, patient_uuid_2: patient_uuid_2 }
      )
      MCP::Tool::Response.new([ { type: "text", text: result_text } ])
    end

    configuration = MCP::Configuration.new(protocol_version: "2025-06-18")
    configuration.exception_reporter = ->(exception, server_context) do
      $stderr.puts "Exception Reported: #{exception}"
      $stderr.puts "Context: #{server_context}"
    end

    configuration.instrumentation_callback = ->(data) do
      # $stderr.puts "Instrumentation callback: #{data}"
    end

    srv = MCP::Server.new(
      name: NAME,
      title: TITLE,
      version: Rails.application.config.x.version,
      instructions: INSTRUCTIONS,
      tools: @tools || [],
      prompts: [],
      resources: @resources.map(&:mcp_resource),
      resource_templates: @resource_templates.map(&:mcp_resource_template),
      server_context: {}, # TODO
      configuration:
    )

    srv.resources_read_handler do |params|
      if (resource_wrapper = @resources.find { |x| x.match? params })
        resource_wrapper.call
      elsif (template_wrapper = @resource_templates.find { |x| x.match? params })
        template_wrapper.call(params)
      else
        raise StandardError, "Resource #{params[:uri]} not found"
        # TODO: Get MCP Ruby SDK to return a -32002 code which is a SHOULD under mcp spec
        # Returning the error JSON payload directly causes it to get wrapped in a
        # "positive response" payload creating an erroneous response. Raising
        # any exception only causes -32603 internal error response.
      end
    end

    srv
  end

  # @return [MCP::Server] for HTTP Streamable transport
  def mcp_streamable_http
    server
  end

  # @return [MCP::Server::Transports::StdioTransport] server for stdio transport
  def mcp_stdio
    MCP::Server::Transports::StdioTransport.new(server)
  end
end
