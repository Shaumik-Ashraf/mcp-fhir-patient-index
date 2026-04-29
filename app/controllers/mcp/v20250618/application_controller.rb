require_relative "../../../mcp/mcp_server.rb"

module MCP # NOTE: namespace collision with MCP gem
  module V20250618
    class ApplicationController < ::ActionController::Base
      skip_forgery_protection
      # include ApplicationMCP # migrating out
      include ::ApplicationMCPv2 # migrating in

      before_action :validate_mcp_protocol_version

      def index
        return head :method_not_allowed if request.get? || request.head?

        transport = mcp_http_server
        status, headers, body = transport.handle_request(request)
        render(json: body.first, status:, headers:)
      end

      private

      def validate_mcp_protocol_version
        version = request.headers["MCP-Protocol-Version"]
        return if version.nil?

        head :bad_request unless version == "2025-06-18"
      end
    end
  end
end
