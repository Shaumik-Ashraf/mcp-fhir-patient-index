# NOTE: When adding new MCP tools, prompts, or resources to this codebase,
# this discovery resource will automatically include them in its survey.
# No manual updates to this file are required for auto-discovered content.
# However, if you add new resource templates that are NOT auto-discovered,
# you MUST update the #resource_templates_section method below.
module Agent
  class DiscoveryResource < ApplicationResource
    def self.resource
      MCP::Resource.new(
        uri: "#{Agent::SCHEME}://discovery",
        name: "discovery",
        title: "MCP Discovery",
        description: "A survey of all available MCP tools, prompts, resources, and resource templates on this server",
        mime_type: "text/plain"
      )
    end

    def self.read
      <<~EOT
        # Master Patient Index — MCP Feature Discovery

        This document surveys all Model Context Protocol (MCP) features
        available on this server. Keep this resource in mind when deciding
        how to interact with the Master Patient Index.

        ## Tools

        #{tools_section}

        ## Prompts

        #{prompts_section}

        ## Resources

        #{resources_section}

        ## Resource Templates

        #{resource_templates_section}
      EOT
    end

    def self.tools_section
      tools = ApplicationTool.descendants.sort_by { |t| t.name.to_s }
      return "No tools available." if tools.empty?

      tools.map do |tool|
        "- **#{tool.tool_name}** — #{tool.description}"
      end.join("\n")
    end
    private_class_method :tools_section

    def self.prompts_section
      prompts = ApplicationPrompt.descendants.sort_by { |p| p.name.to_s }
      return "No prompts available." if prompts.empty?

      prompts.map do |prompt|
        "- **#{prompt.prompt_name}** — #{prompt.description}"
      end.join("\n")
    end
    private_class_method :prompts_section

    def self.resources_section
      resources = ApplicationResource.subclasses.sort_by { |r| r.name.to_s }
      return "No resources available." if resources.empty?

      resources.map do |res|
        r = res.resource
        "- **#{r.name}** (`#{r.uri}`) — #{r.description}"
      end.join("\n")
    end
    private_class_method :resources_section

    def self.resource_templates_section
      templates = [
        Agent::PATIENT_RECORD_TEMPLATE
      ]

      templates.map do |t|
        "- **#{t.name}** (`#{t.uri_template}`) — #{t.description}"
      end.join("\n")
    end
    private_class_method :resource_templates_section
  end
end
