Dir.glob("**/*", base: __dir__).each { |dependency| require_relative dependency }

# @example
#   class MyController < ApplicationController
#     def index
#       render json: ActionMCP.handle_json(request)
#     end
#   end
class ActionMCP
  @@server = MCP::Server.new(
    name: "master_patient_index_mcp_server",
    title: "Master Patient Index",
    version: "0.0.0", # TODO: consolidate versions across app, fhir, and mcp
    instructions: "See https://github.com/Shaumik-Ashraf/mcp-fhir-patient-index/README.md",
    tools: ApplicationTool.descendants,
    prompts: ApplicationPrompt.descendants,
    resources: ApplicationResource.descendants,
    resource_templates: ApplicationResourceTemplate.descendants,
    server_context: {} # TODO https://github.com/modelcontextprotocol/ruby-sdk?tab=readme-ov-file#server_context
  )

  # @param request [ActionDispatch::Request]
  # @return [#as_json] MCP response
  def self.handle_json(request)
    @@server.handle_json(request.body.read)
  rescue StandardError => e
    Rails.logger.error "ActionMCP Error: #{e}"
    { jsonrpc: "2.0", id: request.params[:id], error: { code: 500, message: e.full_message, data: e.to_hash } }
  end
end
