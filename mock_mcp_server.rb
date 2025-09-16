#!/usr/bin/env ruby

require 'fast_mcp'

# Create an MCP server
server = FastMcp::Server.new(name: 'my-ai-server', version: '1.0.0')

# Define a tool by inheriting from FastMcp::Tool
class SummarizeTool < FastMcp::Tool
  description "Summarize a given text"

  arguments do
    required(:text).filled(:string).description("Text to summarize")
    optional(:max_length).filled(:integer).description("Maximum length of summary")
  end

  def call(text:, max_length: 100)
    # Your summarization logic here
    text.split('.').first(3).join('.') + '...'
  end
end

# Register the tool with the server
server.register_tool(SummarizeTool)

# Create a resource by inheriting from FastMcp::Resource
class StatisticsResource < FastMcp::Resource
  uri "data/statistics"
  resource_name "Usage Statistics"
  description "Current system statistics"
  mime_type "application/json"

  def content
    JSON.generate({
      users_online: 120,
      queries_per_minute: 250,
      popular_topics: ["Ruby", "AI", "WebDev"]
    })
  end
end

# Register the resource with the server
server.register_resource(StatisticsResource)

# Start the server
server.start
