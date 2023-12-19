module Agents
  class AlgorithmiaAgent < Agent

    can_dry_run!

    default_schedule "every_10m"

    description <<-MD
      The AlgoritmiaAgent runs algorithms from [Algorithmia](https://algorithmia.com).

      You need to register an account before using this Agent.

      The created event will have the output from Algorithmia in the `result` key.
      To merge incoming Events with the result, use `merge` for the `mode` key.

    MD

    def default_options
      {
        'api_key' => 'my_algorithmia_key',
        'algorithm' => 'nlp/AutoTag/1.0.1',
        'input' => '{{event.data}}',
        'mode' => 'merge'
      }
    end

    def validate_options
      errors.add(:base, "api_key is required ") unless options['api_key'].present?
      errors.add(:base, "algorithm is required ") unless options['algorithm'].present?
      errors.add(:base, "input is required ") unless options['input'].present?
    end

    def working?
      !recent_error_logs?
    end

    def check
      handle(interpolated['algorithm'], interpolated['input'])
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          algo = interpolated['algorithm']
          input = interpolated['input']
          existing_payload = interpolated['mode'].to_s == "merge" ? event.payload : {}
          handle algo, input, existing_payload
        end
      end
    end

    private

    def handle(algorithm, input, payload = {})
      algo = client.algo(algorithm)
      payload[:result] = algo.pipe(input).result
      create_event payload: payload
    end

    def client
      Algorithmia.client(interpolated['api_key'])
    end
  end
end
