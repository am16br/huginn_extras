require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::AlgorithmiaAgent do
  before do
    @valid_params = {
      name: "somename",
      options:       {
        api_key: '{% credential my_algorithmia_key %}',
        algorithm: 'nlp/AutoTag/1.0.1',
        input: '{{event.data}}'
      }
    }

    stub_request(:post, /api\.algorithmia\.com/)
    .to_return(
      :body => File.read(File.join(__dir__,"fixtures/autotag.json")),
      :status => 200,
      :headers => {"Content-Type" => "application/json; charset=utf-8"}
    )

    @expected_body = ''
    @expected_headers = {
      "Content-Type" => 'application/json',
      "Authorization": 'Simple something'
    }

    users(:jane).user_credentials.create! credential_name: 'my_algorithmia_key', credential_value: 'something'
    @checker = Agents::AlgorithmiaAgent.new(@valid_params)
    @checker.user = users(:jane)
    @checker.save!

  end

  describe "#check" do

    it "creates an Events with the received data" do
      @checker.check()
      expect(Event.last.payload['result']).to eq ["extended", "flyby", "interstellar", "mission", "space", "spacecraft", "titan", "voyager"]
    end
  end

  describe "#receive" do
    describe "with an input from event" do
      before do
        @event = Event.new
        @event.agent = agents(:bob_rain_notifier_agent)
        @event.payload = {
          'text' => 'Some text',
          'some_key' => 'much data'
        }
      end

      it "should use input from event" do
        @checker.options[:input] = '{{text}}'
        @checker.receive([@event])

        expect(
          a_request(:post, "https://api.algorithmia.com/v1/algo/#{@checker.options['algorithm']}")
          .with(
            body: "Some text",
            headers: {'Content-Type'=>'text/plain', 'User-Agent'=>'Algorithmia Ruby Client', 'Authorization': 'something'}
          )
        ).to have_been_made
      end

      it "should create an Event" do
        expect {
          @checker.receive([@event])
        }.to change { Event.count }.by(1)
      end

      it "should support merging of events" do
        expect {
          @checker.options[:mode] = "merge"
          @checker.receive([@event])
        }.to change { Event.count }.by(1)
        last_payload = Event.last.payload
        expect(last_payload['some_key']).to eq('much data')
        expect(last_payload['result']).to eq ["extended", "flyby", "interstellar", "mission", "space", "spacecraft", "titan", "voyager"]
      end
    end
  end

  describe "validation" do
    before do
      expect(@checker).to be_valid
    end

    it "should validate presence of api_key key" do
      @checker.options[:api_key] = nil
      expect(@checker).not_to be_valid
    end

    it "should validate presence of algorithm key" do
      @checker.options[:algorithm] = nil
      expect(@checker).not_to be_valid
    end

    it "should validate presence of input key" do
      @checker.options[:input] = nil
      expect(@checker).not_to be_valid
    end
  end
end
