module Agent
  SCHEME = "mpi"

  PATIENT_RECORD_TEMPLATE = MCP::ResourceTemplate.new(
    uri_template: "#{SCHEME}://patient_record/{id}",
    name: "patient_record",
    title: "Patient Record",
    description: "Patient resource parameterized by UUID",
    mime_type: "text/plain"
  )

  # @private
  def mcp_server(context)
    server = MCP::Server.new(
      name: Rails.application.name.underscore,
      title: Rails.application.name.humanize,
      version: Rails.application.config.x.version,
      instructions: "Use these tools and resources to interact with the master patient index.",
      tools: ApplicationTool.descendants,
      prompts: ApplicationPrompt.descendants,
      resources: ApplicationResource.subclasses.map(&:resource),
      resource_templates: [ PATIENT_RECORD_TEMPLATE ],
      server_context: {}.merge(context)
    )

    server.resources_read_handler do |params|
      uri = params[:uri]
      resource_class = ApplicationResource.subclasses.find { |klass| klass.resource.uri == uri }
      if resource_class
        [ { uri:, mimeType: resource_class.resource.mime_type, text: resource_class.read } ]
      elsif uri =~ /\Ampi:\/\/patient_record\/(.+)\z/
        patient = PatientRecord.find_by!(uuid: $1)
        [ { uri:, mimeType: "text/plain", text: patient.to_text } ]
      else
        raise StandardError, "Resource #{uri} not found"
      end
    end

    server
  end

  # @param context [Hash | nil]
  # @return [#handle_json]
  # @example
  #   class MCPController < ActionController::API
  #     def create
  #       transport = mcp_http_server
  #       status, headers, body = transport.handle_request(request)
  #       render(json: body.first, status: status, headers: headers)
  #     end
  #   end
  def mcp_http_server(context = {})
    MCP::Server::Transports::StreamableHTTPTransport.new(mcp_server(context), stateless: true)
  end

  # @param context [Hash]
  # @return [#open]
  # @example
  #   transport = mcp_stdio(cli: true)
  #   transport.open
  #   # stdin: {"jsonrpc":"2.0","id":"1","method":"initialize"}
  #   # stdout: {}
  def mcp_stdio(context = {})
    MCP::Server::Transports::StdioTransport.new(mcp_server(context))
  end

  private
end
