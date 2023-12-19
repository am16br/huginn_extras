require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::OpenaiAssistantAgent do
  before(:each) do
    @valid_options = Agents::OpenaiAssistantAgent.new.default_options
    @checker = Agents::OpenaiAssistantAgent.new(:name => "OpenaiAssistantAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
