require 'rails_helper'

RSpec.describe "pages/index.html.erb", type: :view do
  it "renders project title" do
    render

    expect(rendered).to match /Master Patient Index/i
  end
end
