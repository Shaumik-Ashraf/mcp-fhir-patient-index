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
  VERSION = "0.1.0" # TODO: consolidate versions across app, fhir, and mcp
  INSTRUCTIONS = <<~EOT
    See https://github.com/Shaumik-Ashraf/mcp-fhir-patient-index/README.md
  EOT

  @tools = []
  @prompts = []
  @resources = [] # Array<Hash<MCP::Resource, block>>
  @resource_templates = [] # Array<ResourceTemplatewrapper>

  # @param [String] endpoint - the mcp base name from which url and name are derived
  # @param [String] mime_type
  # @yield block that is called when MCP resource is queried
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
      @callable.call
    end
  end

  # @private
  class ResourceTemplateWrapper
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
        # omit description
        mime_type: case klass
                   when ->(k) { k.instance_methods.include? :to_text }
                     "text/plain"
                   when ->(k) { k.instance_methods.include? :to_json }
                     "text/json"
                   else
                     raise StandardError, "#{klass} does not respond to #to_text or #to_json"
                   end
      )
    end

    def name
      mcp_resource_template.name
    end

    def uri_regex
      resource_template_uri_regex(klass)
    end

    def blk
      ->(params) { klass.find(params[:id]) }
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
    define_resource "info", "text/plain", "Retrieve MCP Server Info", "...", (lambda do
      <<~EOT
        This is a master patient index server that supports model context
        protocol (MCP). It contains patient records of demographic information
        for retrieval, matching, and de-duplication.
      EOT
    end)

    define_resource "all", "text/plain", "Retrieve all Patient Records", "...", (lambda do
      PatientRecord.all.map(&:to_text).join("\n")
    end)

    load_application_records_as_resource_templates(PatientRecord)

    #puts "DEBUG: MCP Name: #{NAME}"
    #puts "DEBUG: MCP Resources: #{@resources.map(&:keys).flatten.map(&:name).join(', ')}"
    #puts "DEBUG: MCP Resource Templates: #{@resource_templates.map(&:name).join(', ')}"

    srv = MCP::Server.new(
      name: NAME,
      title: TITLE,
      version: VERSION,
      instructions: INSTRUCTIONS,
      tools: [],
      prompts: [],
      resources: @resources.map(&:mcp_resource),
      resource_templates: @resource_templates.map(&:mcp_resource_template),
      server_context: {} # TODO https://github.com/modelcontextprotocol/ruby-sdk?tab=readme-ov-file#server_context
    )

    srv.resources_read_handler do |params|
      if (resource_wrapper = @resources.find { |x| x.match? params })
        resource_wrapper.call
      elsif (template_wrapper = @resource_templates.find { |x| x.uri_regex.match? params[:uri] })
        template_wrapper.blk.call
      # TODO: prompts, tools
      else
        $stderr.puts "ActionMCP Error 1: #{e}"
        {
          jsonrpc: "2.0",
          id: request.params[:id],
          error: { code: -32002, message: "Resource not found" }
        }
      end
    rescue ActiveRecord::RecordNotFound => e
      $stderr.puts "ActionMCP Error 2: #{e}"
      {
        jsonrpc: "2.0",
        id: request.params[:id],
        error: { code: -32002, message: "Resource not found" }
      }
    rescue StandardError => e
      $stderr.puts "ActionMCP Error 3: #{e}"
      {
        jsonrpc: "2.0",
        id: request.params[:id],
        error: { code: -32603, message: e.full_message, data: e.to_hash }
      }
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

