require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::Mongodb do
  before(:each) do
    @valid_options = Agents::Mongodb.new.default_options
    @checker = Agents::Mongodb.new(:name => "Mongodb", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
