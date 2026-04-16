module MCP # NOTE: namespace collision with MCP gem
  module V20250618
    class ApplicationController < ::ActionController::Base
      skip_forgery_protection
      include ApplicationMCP

      before_action :validate_mcp_protocol_version

      def index
        return head :method_not_allowed if request.get? || request.head?

        render json: mcp_streamable_http.handle_json(request.body.read)
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
