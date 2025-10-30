require 'rails_helper'

RSpec.describe "Settings", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/setting/index"
      expect(response).to have_http_status(:success)
    end
  end
end
