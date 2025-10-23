require 'rails_helper'

RSpec.describe Util do
  let(:klass) do
    Class.new do
      extend Util
    end
  end

  # TODO: more thorough tests
  it "can create a string with typos" do
    expect(klass.typo("hello", randomness: 0.99)).not_to eq "hello"
  end
end
