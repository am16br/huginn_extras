#https://github.com/hihouhou/huginn_microsoft_teams_agent
module Agents
  class MicrosoftTeamsAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule "never"

    description do
      <<-MD
      The Microsoft Teams Agent receives and collects events and sends them via [Microsoft Teams](https://www.microsoft.com/en-us/microsoft-teams/group-chat-software/).

      `webhook_url` provides a unique URL, to send a JSON payload with a message in card format.

      `debug` is used for verbose mode.

      `message` is the sent message.

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days
      that you anticipate passing without this Agent receiving an incoming Event.
      MD
    end


    def default_options
      {
        'debug' => 'false',
        'webhook_url' => '',
        'message' => '',
        'expected_receive_period_in_days' => '2',
      }
    end

    form_configurable :debug, type: :boolean
    form_configurable :webhook_url, type: :string
    form_configurable :message, type: :string
    form_configurable :expected_receive_period_in_days, type: :string
    def validate_options

      unless options['webhook_url'].present?
        errors.add(:base, "webhook_url is a required field")
      end

      unless options['message'].present?
        errors.add(:base, "message is a required field")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      received_event_without_error? && !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          log event
          send_message
        end
      end
    end

    def check
      send_message
    end

    private

    def send_message()

      uri = URI.parse(interpolated['webhook_url'])
      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/json"
      request.body = JSON.dump({
        "text" => "#{interpolated['message']}"
      })

      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      log "request status : #{response.code}"

      if interpolated['debug'] == 'true'
        log response.body
      end

    end
  end
end
