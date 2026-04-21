# config/initializers/cors.rb

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"
    resource "*", headers: :any, methods: %i[get post patch put delete head options]
  end

  # Chat page: allow cross-origin requests from anywhere so the browser can
  # call external LLM APIs (Anthropic, OpenAI, etc.) from this page.
  # allow do
  #   origins "*"
  #   resource "/chat", headers: :any, methods: [ :get, :options ]
  # end

  # allow do
  #   origins "http://127.0.0.1:80",
  #           "http://localhost:80",
  #           "http://127.0.0.1:3000",
  #           "http://localhost:3000",
  #           "http://127.0.0.1:6274",
  #           "http://localhost:6274",
  #           "http://127.0.0.1:1234",
  #           "http://localhost:1234"
  #   resource "*", headers: :any, methods: [ :get, :post, :patch, :put, :delete, :head, :options ]
  # end
end
