module Agent
  # @private
  def mcp_server(context)
    MCP::Server.new(
      name: Rails.application.name.underscore,
      title: Rails.application.name.humanize,
      version: Rails.application.config.x.version,
      instructions: "Use these tools and resources to interact with the master patient index.",
      tools: ApplicationTool.descendants,
      prompts: ApplicationPrompt.descendants,
      resources: ApplicationResource.descendants,
      server_context: {}.merge(context)
    )
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
end
