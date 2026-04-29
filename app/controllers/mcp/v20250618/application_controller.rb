module MCP # NOTE: namespace collision with MCP gem
  module V20250618 # TODO: update to V20251125
    class ApplicationController < ::ActionController::Base
      skip_forgery_protection
      # include ApplicationMCP # migrating out
      include ::Agent          # migrating in

      def index
        head(:method_not_allowed) and return if request.get? || request.head?
        # head(:bad_request) and return if request.headers.fetch("MCP-Protocol-Version", "2025-06-08") != "2025-06-8"
        # Omit because MCP inspector is now using version 2025-11-25
        # Assume correct version is sent by the robustness principle

        transport = mcp_http_server()
        status, headers, body = transport.handle_request(request)
        render(json: body.first, status:, headers:)
      end
    end
  end
end
