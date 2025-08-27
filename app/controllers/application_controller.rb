class ApplicationController < ActionController::Base
  before_action :set_title
  before_action :set_metas

  protected

  def set_title(str = nil)
    @title = str
    @title ||= params[:controller].to_s.capitalize + " " + params[:action].to_s.capitalize
  end

  def set_metas
    @metas = [
      { name: "robots", content: "index,follow" },
      { name: "keywords", content: "Master Patient Index,MPI,EMPI,FHIR,MCP,LLM integration,Health Technology" },
      { name: "description", content: "A master patient index with FHIR API and MCP server." },
      { name: "language", content: "EN" }
    ]
  end

  def robots(index_or_follow)
    idx = @metas.index { |x| x&.key?(:name) && (x[:name] == "robots") }
    @metas[0][:content] = index_or_follow
  end

  public

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
