Dir.glob("**/*", base: __dir__).each { |dependency| require_relative dependency }

# @example
#   class MyController < ApplicationController
#     def index
#       render json: ActionMCP.handle_json(request)
#     end
#   end
class ActionMCP
  SCHEME = "master-patient-index"

  @@server = MCP::Server.new(
    name: "master_patient_index_mcp_server",
    title: "Master Patient Index",
    version: "0.0.0", # TODO: consolidate versions across app, fhir, and mcp
    instructions: "See https://github.com/Shaumik-Ashraf/mcp-fhir-patient-index/README.md",
    tools: [],
    prompts: [],
    resources: [
      ApplicationResource.new(
        uri: "#{SCHEME}://info",
        name: "info_resource",
        title: "Patient Resource",
        description: "MCP server resource for Patient Records.",
        mime_type: "text/plain"
      ),
      ApplicationResource.new(
        uri: "#{SCHEME}://all",
        name: "all_patients_resource",
        title: "All Patient Resources",
        description: "All patient resources returned at once. This resource will not require pagination.",
        mime_type: "text/plain"
      )
    ],
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

  @@server.resources_read_handler do |params|
    case params[:uri]
    when "#{SCHEME}://info"
      [{ uri: "#{SCHEME}://info", mimeType: "text/plain", text: "This is a master patient index server that supports MCP." }]
    when "#{SCHEME}://all"
      [{ uri: "#{SCHEME}://all", mimeType: "text/plain", text: PatientRecord.all.map(&:to_text).join("\n\n") }]
    when %r[#{Regexp.escape(SCHEME)}://patient]
      [{ uri: "#{SCHEME}://patient", mimeType: "text/plain", text: PatientRecord.find_by!(uuid: params[:uuid]).to_text }]
    else
      # TODO
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
