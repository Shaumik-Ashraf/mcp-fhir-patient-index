namespace :mcp do
  task :load => [:environment] do
    include ApplicationMCP
  end

  desc "Run MCP Server in STDIO mode"
  task stdio: :load do
    mcp_stdio.open
  end

  desc "Open shell wrapper around MCP STDIO mode"
  task shell: :load do
    class Shell
      def id
        @id ||= 0
        @id += 1
      end

      def run
        puts <<~EOT
          Welcome to the MCP Shell.

          Example:
            mcp-shell>initialize
            request:
            {"jsonrpc":"2.0","id":1,"method":"initialize"}
            response:
            ...

            mcp-shell>resources/read, uri:app://info
            request:
            {"jsonrpc":"2.0","id":2,"method":"resources/read","params":{"uri":"app://info"}}

            response:
            ...

            mcp-shell>exit
        EOT

        loop do
          print("mcp-shell>")
          tokens = gets.split(",").map(&:strip)
          method = tokens.shift
          break if method == "exit"

          params = tokens.map { |token| token.split(":", 2).each(&:strip) }.to_h
          request = { jsonrpc: "2.0", id: id, method:, params: }.to_json
          puts "request"
          puts request
          print("\n")

          puts "response"
          puts mcp_streamable_http.handle_json(request)
          print("\n")
        end
      end
    end
    Shell.new.run
  end
end
