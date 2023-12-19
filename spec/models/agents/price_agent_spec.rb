require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::PriceAgent do
  before(:each) do
    @valid_options = Agents::PriceAgent.new.default_options
    @checker = Agents::PriceAgent.new(:name => "PriceAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
