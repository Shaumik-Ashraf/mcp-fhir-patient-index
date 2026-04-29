module MCP # NOTE: namespace collision with MCP gem
  module V20250618 # TODO: update to V20251125
    class ApplicationController < ::ActionController::Base
      skip_forgery_protection
      # include ApplicationMCP # migrating out
      include ::Agent          # migrating in

      SUPPORTED_PROTOCOL_VERSIONS = %w[2025-06-18 2025-11-25].freeze

      def index
        head(:method_not_allowed) and return if request.get? || request.head?
        version = request.headers["MCP-Protocol-Version"]
        head(:bad_request) and return if version.present? && !SUPPORTED_PROTOCOL_VERSIONS.include?(version)

        transport = mcp_http_server()
        status, headers, body = transport.handle_request(request)
        render(json: body.first, status:, headers:)
      end
    end
  end
end
