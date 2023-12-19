require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::BigqueryAgent, :vcr do
  before(:each) do
    @valid_options = Agents::BigqueryAgent.new.default_options
    @checker = Agents::BigqueryAgent.new(:name => "BigqueryAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
