module MCP # NOTE: namespace collision with MCP gem
  module V20250618
    class ApplicationController < ::ActionController::Base
      skip_forgery_protection
      include ActionMCP

      def index
        render json: mcp_streamable_http.handle_json(request.body.read)
      end
    end
  end
end
