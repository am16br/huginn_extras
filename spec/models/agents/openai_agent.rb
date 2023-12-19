require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::OpenaiAgent do
  before(:each) do
    @valid_options = Agents::OpenaiAgent.new.default_options
    @checker = Agents::OpenaiAgent.new(:name => "OpenaiAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
