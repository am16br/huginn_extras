require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::MicrosoftTeamsAgent do
  before(:each) do
    @valid_options = Agents::MicrosoftTeamsAgent.new.default_options
    @checker = Agents::MicrosoftTeamsAgent.new(:name => "MicrosoftTeamsAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
