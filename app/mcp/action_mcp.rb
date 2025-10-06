Dir.glob("**/*", base: __dir__).each { |dependency| require_relative dependency }

# @example
#   class MyController < ApplicationController
#     include ActionMCP
#     def index
#       render json: mcp_streamable_http.handle_json(request.body.read)
#     end
#   end
#
# @example
#   class CLI
#     include ActionMCP
#     def run
#       mcp_stdio.open
#     end
#   end
module ActionMCP
  SCHEME = "master-patient-index"
  NAME = Rails.application.name.underscore
  TITLE = Rails.application.name.humanize
  VERSION = "0.0.0" # TODO: consolidate versions across app, fhir, and mcp
  INSTRUCTIONS = <<~EOT
    See https://github.com/Shaumik-Ashraf/mcp-fhir-patient-index/README.md
  EOT
  ID_REGEX = "[A-Za-z0-9_-]+"

  @tools = []
  @prompts = []
  @resources = []
  @resource_templates = []

  def define_resource(endpoint, mime_type, title=nil, description=nil, &block)
    @resources ||= []
    @resources << {
      MCP::Resource.new(
        uri: "#{SCHEME}://#{endpoint}",
        name: endpoint.to_s.underscore,
        title:,
        description:,
        mime_type:
      ) => block
    }
  end

  def load_application_records_as_resource_templates(*klasses)
    klasses.each do |klass|
      @resource_templates << Struct.new(
        mcp_resource_template: MCP::ResourceTemplate.new(
          uri: "#{SCHEME}://#{klass.underscore.singularize}/{id}",
          name: klass.to_s.underscore.singularize,
          title: klass.to_s.humanize,
          # omit description
          mime_type: case klass
                     when ->(k) { k.instance_methods.include? :to_text }
                       "text/plain"
                     when ->(k) { k.instance_methods.include? :to_json }
                       "text/json"
                     else
                       raise StandardError, "ApplicationRecord #{klass} does not respond to #to_text or #to_json"
                     end
        ),
        uri_regex: %r{#{Regexp.escape(klass.underscore.singularize)}/(#{ID_REGEX})},
        blk: ->(params) { klass.find(params[:id]) }
      )
    end
  end

  def resource_template_uri(klass)
    "#{reource_template_uri_prefix}/{id}"
  end

  def resource_template_uri_prefix(klass)
    "#{SCHEME}://#{klass.underscore.singularize}"
  end

  def server
    define_resource "info", "text/plain", "MCP Server Information" do
      <<~EOT
        This is a master patient index server that supports model context
        protocol (MCP). It contains patient records of demographic information
        for retrieval, matching, and de-duplication.
      EOT
    end

    define_resource "all", "text/plain", "All", "Retrieve all patient records" do
      PatientRecord.all.map(&:to_text).join("\n")
    end

    load_application_records_as_resource_templates(PatientRecord)

    # TODO: create patient tool

    srv = MCP::Server.new(
      name: NAME,
      title: TITLE,
      version: VERSION,
      instructions: INSTRUCTIONS,
      tools: [],
      prompts: [],
      resources: @resources.keys,
      resource_templates: [
        ApplicationResourceTemplate.new(
          uri_template: "#{SCHEME}://patient/{uuid}",
          name: "patient_resource_template",
          title: "Patient Resource parameterized by UUID",
          description: "Patient resource by primary id (UUID)",
          mime_type: "text/plain"
        )
      ],
      server_context: {} # TODO https://github.com/modelcontextprotocol/ruby-sdk?tab=readme-ov-file#server_context
    )

    srv.resources_read_handler do |params|
      @resources.each do |mcp_resource, blk|
        if mcp_resource.uri == params[:uri]
          return blk.call
        end
      end

      @resource_templates.each do |struct|
        if struct.uri_regex.match? params[:uri]
          return struct.blk.call
        end
      end

      raise StandardError, "MCP Parameters did not map to a tool, prompt, resource, or resource template: #{params}"
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.warn "ActionMCP Error: #{e}"
      { jsonrpc: "2.0",
        id: request.params[:id],
        error: { code: -32002, message: "Resource not found" } }
    rescue StandardError => e
      Rails.logger.error "ActionMCP Error: #{e}"
      { jsonrpc: "2.0",
        id: request.params[:id],
        error: { code: -32603, message: e.full_message, data: e.to_hash } }
    end
  end

  def mcp_streamable_http
    server
  end

  def mcp_stdio
    MCP::Server::Transports::StdioTransport.new(server)
  end
end
