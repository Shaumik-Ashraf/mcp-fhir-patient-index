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
    tools: [],
    prompts: [],
    resources: [
      ApplicationResource.new(
        uri: "http://example.com/info",
        name: "patient_resource",
        title: "Patient Resource",
        description: "MCP server resource for Patient Records.",
        mime_type: "text/plain"
      )
    ],
    resource_templates: [
      ApplicationResourceTemplate.new(
        uri_template: "http://example.com/patient/{uuid}",
        name: "patient_resource_template",
        title: "Patient Resource parameterized by UUID",
        description: "Patient resource by primary id (UUID)",
        mime_type: "text/plain"
      )
    ],
    server_context: {} # TODO https://github.com/modelcontextprotocol/ruby-sdk?tab=readme-ov-file#server_context
  )

  @@server.resources_read_handler do |params|
    case params[:uri]
    when "http://example.com/info"
      { uri: "http://example.com/patient", mimeType: "text/plain", text: "This is a master patient index server that supports MCP." }
    when %r[http://example.com/patient]
      { uri: "http://example.com/patient", mimeType: "text/plain", text: PatientRecord.find_by!(uuid: params[:uuid]).to_text }
    else

    end
  end

  # @param request [ActionDispatch::Request]
  # @return [#as_json] MCP response
  def self.handle_json(request)
    @@server.handle_json(request.body.read)
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "ActionMCP Error: #{e}"
    { jsonrpc: "2.0", id: request.params[:id], error: { code: -32002, message: "Resource not found" } }
  rescue StandardError => e
    Rails.logger.error "ActionMCP Error: #{e}"
    { jsonrpc: "2.0", id: request.params[:id], error: { code: -32603, message: e.full_message, data: e.to_hash } }
  end
end
