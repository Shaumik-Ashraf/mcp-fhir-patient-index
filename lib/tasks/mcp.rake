require "readline"

namespace :mcp do
  task load: [ :environment ] do
    include Agent
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
            mcp-shell> resources/read {"uri": "mpi://info"}
            mcp-shell> resources/read, uri:mpi://info

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
        req_id  = id
        request = { jsonrpc: "2.0", id: req_id, method: method_name, params: params }.to_json

        puts "\n── request ────────────────────────────────────"
        puts JSON.pretty_generate(JSON.parse(request))

        result = stdio_request(req_id, method_name, params)

        puts "\n── response ───────────────────────────────────"
        puts JSON.pretty_generate(result)
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
    resources = stdio_request(1, "resources/list").dig("result", "resources") || []

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

    templates = stdio_request(2, "resources/templates/list").dig("result", "resourceTemplates") || []

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

    tools = stdio_request(1, "tools/list").dig("result", "tools") || []

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

  # Sends a single JSON-RPC request through the stdio transport by temporarily
  # redirecting $stdin/$stdout to StringIO buffers, then restoring via STDIN/STDOUT.
  # @param id [Integer] JSON-RPC request ID
  # @param method [String] MCP method name (e.g. "resources/list")
  # @param params [Hash] method parameters
  # @return [Hash] parsed JSON response
  def stdio_request(id, method, params = {})
    request_json = { jsonrpc: "2.0", id:, method:, params: }.to_json
    $stdin  = StringIO.new(request_json + "\n")
    $stdout = StringIO.new
    mcp_stdio.open
    JSON.parse($stdout.string.strip)
  ensure
    $stdin  = STDIN
    $stdout = STDOUT
  end
end
