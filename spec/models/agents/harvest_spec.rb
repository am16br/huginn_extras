require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::Harvest do
  before(:each) do
    @valid_options = Agents::Harvest.new.default_options
    @checker = Agents::Harvest.new(:name => "Harvest", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
