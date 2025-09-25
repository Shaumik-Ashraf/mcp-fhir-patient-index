module MCP # NOTE: namespace collision with MCP gem
  module V20250618
    class ApplicationController < ::ApplicationController
      skip_forgery_protection

      def index
        render json: ActionMCP.handle_json(request)
      end
    end
  end
end
