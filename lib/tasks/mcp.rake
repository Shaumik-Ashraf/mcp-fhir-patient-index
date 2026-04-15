require "readline"

namespace :mcp do
  task load: [ :environment ] do
    include ApplicationMCP
  end

  desc "Run MCP Server in STDIO mode"
  task stdio: :load do
    mcp_stdio.open
  end

  desc "Open shell wrapper around MCP STDIO mode"
  task shell: :load do
    class Shell
      METHODS = %w[
        initialize
        ping
        resources/list
        resources/read
        resources/templates/list
        tools/list
        tools/call
        prompts/list
        prompts/get
      ].freeze

      def id
        @id ||= 0
        @id += 1
      end

      def run
        print_banner

        loop do
          line = Readline.readline("mcp-shell> ", true)
          break if line.nil?
          line = line.strip
          next if line.empty?

          case line
          when "exit", "quit"
            break
          when "help", "?"
            print_help
          else
            dispatch(line)
          end
        end

        puts "\nBye."
      end

      private

      def print_banner
        puts <<~BANNER
          ═══════════════════════════════════════════════
          Welcome to the MCP Shell
          ═══════════════════════════════════════════════

          Syntaxes:
            mcp-shell> initialize
            mcp-shell> resources/read {"uri": "master-patient-index://info"}
            mcp-shell> resources/read, uri:master-patient-index://info

          Type 'help' for a list of MCP methods.
          Type 'exit' or 'quit' to leave.
          ═══════════════════════════════════════════════
        BANNER
      end

      def print_help
        puts "\nAvailable MCP methods:"
        METHODS.each { |m| puts "  #{m}" }
        puts
      end

      def dispatch(line)
        method_name, params = parse_input(line)
        request = { jsonrpc: "2.0", id: id, method: method_name, params: params }.to_json

        puts "\n── request ────────────────────────────────────"
        puts JSON.pretty_generate(JSON.parse(request))

        response = mcp_streamable_http.handle_json(request)

        puts "\n── response ───────────────────────────────────"
        puts JSON.pretty_generate(JSON.parse(response))
        puts "───────────────────────────────────────────────\n"
      rescue JSON::ParserError => e
        puts "JSON parse error: #{e.message}"
      rescue => e
        puts "Error: #{e.message}"
      end

      def parse_input(line)
        first_space = line.index(" ")
        return [ line.strip, {} ] if first_space.nil?

        method_name = line[0, first_space].strip.delete_suffix(",")
        rest = line[first_space..].strip

        if rest.start_with?("{")
          [ method_name, JSON.parse(rest) ]
        else
          parse_csv_params(method_name, rest)
        end
      end

      def parse_csv_params(method_name, rest)
        rest = rest.delete_prefix(",").strip
        return [ method_name, {} ] if rest.empty?

        params = rest.split(",").each_with_object({}) do |token, hash|
          key, value = token.split(":", 2).map(&:strip)
          hash[key] = value unless key.nil? || key.empty?
        end

        [ method_name, params ]
      end
    end

    Shell.new.run
  end

  desc "List all MCP resources and resource templates"
  task list_resources: :load do
    srv = mcp_streamable_http

    raw = srv.handle_json({ jsonrpc: "2.0", id: 1, method: "resources/list", params: {} }.to_json)
    resources = JSON.parse(raw).dig("result", "resources") || []

    puts "\n=== Resources (#{resources.size}) ==="
    if resources.empty?
      puts "  (none)"
    else
      resources.each do |r|
        puts "  URI:         #{r['uri']}"
        puts "  Name:        #{r['name']}"
        puts "  Title:       #{r['title']}"        if r["title"]
        puts "  Description: #{r['description']}"  if r["description"]
        puts "  MIME type:   #{r['mimeType']}"     if r["mimeType"]
        puts
      end
    end

    raw2 = srv.handle_json({ jsonrpc: "2.0", id: 2, method: "resources/templates/list", params: {} }.to_json)
    templates = JSON.parse(raw2).dig("result", "resourceTemplates") || []

    puts "=== Resource Templates (#{templates.size}) ==="
    if templates.empty?
      puts "  (none)"
    else
      templates.each do |t|
        puts "  URI Template: #{t['uriTemplate']}"
        puts "  Name:         #{t['name']}"
        puts "  Title:        #{t['title']}"        if t["title"]
        puts "  Description:  #{t['description']}"  if t["description"]
        puts "  MIME type:    #{t['mimeType']}"     if t["mimeType"]
        puts
      end
    end
  end

  desc "List all MCP tools with parameters"
  task list_tools: :load do
    param_desc = lambda do |spec|
      parts = []
      parts << spec["type"]        if spec["type"]
      parts << spec["description"] if spec["description"]
      parts << "one of: #{spec['enum'].join(', ')}" if spec["enum"]
      parts.empty? ? "" : " (#{parts.join('; ')})"
    end

    srv = mcp_streamable_http

    raw = srv.handle_json({ jsonrpc: "2.0", id: 1, method: "tools/list", params: {} }.to_json)
    tools = JSON.parse(raw).dig("result", "tools") || []

    puts "\n=== Tools (#{tools.size}) ==="

    if tools.empty?
      puts "  (none)"
    else
      tools.each do |tool|
        puts "  Tool:        #{tool['name']}"
        puts "  Description: #{tool['description']}"

        schema     = tool["inputSchema"] || {}
        properties = schema["properties"] || {}
        required   = (schema["required"] || []).map(&:to_s)

        if properties.empty?
          puts "  Params:      (none)"
        else
          req_params = properties.select { |k, _| required.include?(k.to_s) }
          opt_params = properties.reject { |k, _| required.include?(k.to_s) }

          unless req_params.empty?
            puts "  Required params:"
            req_params.each { |name, spec| puts "    - #{name}#{param_desc.call(spec)}" }
          end

          unless opt_params.empty?
            puts "  Optional params:"
            opt_params.each { |name, spec| puts "    - #{name}#{param_desc.call(spec)}" }
          end
        end

        puts
      end
    end
  end
end
