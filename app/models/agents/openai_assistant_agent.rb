module Agents
  class OpenaiAssistantAgent < Agent
    include FormConfigurable
    can_dry_run!
    default_schedule "never"
    no_bulk_receive!

    description <<-MD
      The OpenAiAssistant Agent interacts with OpenAI Assistants API. (Some control flow commanding to be done-->agent first gets registered returning asst_id, then thread required to add message(s) returns thread_id, before starting run to allow assistant to use tools (retrieval, interpreter, functions) returns run_id and may take period of time, must wait for status completed to get response) Can also do other LLMs or parameterized code modules.

      The `name` of the assistant.

      The `instructions` telling the assistant what it does.

      The `tools` accessible to the assistant, available: code_interpreter and retrieval (pass file_ids) or function (json defined).

      The `model` used, available: gpt-3.5-turbo-1106 or gpt-4-1106-preview.

      The `files` is not implemented, but the API allows user to pass files as context in messages, or files for retrieval tasks.

      Options should be easily implemented like in the Change Detector Agent or JSON Api Agent to input functions & have predefined data structs to call resources/deploy api

      The `function` is not implemented, but the API allows JSON defined functions like...
      {
          "name": "get_weather",
          "description": "Determine weather in my location",
          "parameters": {
            "type": "object",
            "properties": {
              "location": {
                "type": "string",
                "description": "The city and state e.g. San Francisco, CA"
              },
              "unit": {
                "type": "string",
                "enum": [
                  "c",
                  "f"
                ]
              }
            },
            "required": [
              "location"
            ]
          }
        }

    MD


    event_description <<-MD
      Events look like this:

        {
          "id": "run_Zcv...",
          "object": "assistant",
          "created_at": ...,
          "name": "...",
          "description": null,
          "model": "gpt-3.5-turbo",
          "instructions": "...",
          "tools": [
              {
                "type": "..."
              }
          ],
          "file_ids": [
          ],
          "metadata": {
          }
        }


        {
          "id": "thread_Z0e...",
          "object": "thread",
          "created_at": ...,
          "metadata": {
          }
        }


        {
          "id": "msg_rPQ...",
          "object": "thread.message",
          "created_at": ...,
          "thread_id": "thread_Z0e...",
          "role": "user",
          "content": [
            {
              "type": "text",
              "text": {
                "value": "...",
                "annotations": [

                ]
              }
            }
          ],
          "file_ids": [

          ],
          "assistant_id": null,
          "run_id": null,
          "metadata": {
          }
        }


        {
          "id": "run_Zcv...",
          "object": "thread.run",
          "created_at": 1702904476,
          "assistant_id": "asst_ouq...",
          "thread_id": "thread_Z0e...",
          "status": "in_progress",
          "started_at": 1702904476,
          "expires_at": 1702905076,
          "cancelled_at": null,
          "failed_at": null,
          "completed_at": null,
          "last_error": null,
          "model": "gpt-3.5-turbo",
          "instructions": "...",
          "tools": [
            {
              "type": "..."
            }
          ],
          "file_ids": [

          ],
          "metadata": {
          }
        }
    MD

    def default_options
      {
        'name' => 'Math Tutor',
        'instructions' => 'You are a personal math tutor. Write and run code to answer math questions.',
        'tools' => '[{"type": "code_interpreter"}]',
        'model' => 'gpt-3.5-turbo-1106',
        'OPENAI_API_KEY' => '{% credential OPENAI_API_KEY %}',
        'debug' => 'false',
        'emit_events' => 'true',
        'expected_receive_period_in_days' => '7'
      }
    end

    form_configurable :name, type: :string
    form_configurable :instructions, type: :string
    form_configurable :tools, type: :string
    form_configurable :model, type: :string
    form_configurable :OPENAI_API_KEY, type: :string
    form_configurable :assistant_id, type: :string
    form_configurable :thread_id, type: :string
    form_configurable :run_id, type: :string
    form_configurable :debug, type: :boolean
    form_configurable :emit_events, type: :boolean
    form_configurable :expected_receive_period_in_days, type: :string


    def validate_options
      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          log event
          trigger_action
        end
      end
    end

    def check
      trigger_action
    end

    private

    def log_curl_output(code,body)

      log "request status : #{code}"

      if interpolated['debug'] == 'true'
        log "body"
        log body
      end
    end

    def create_assistant()
      message = { content: interpolated['content'] }.to_json

      # Build the HTTP request to send the message
      uri = URI("https://api.openai.com/v1/assistants")
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      req['Authorization'] = "Bearer #{interpolated['OPENAI_API_KEY']}"
      req['OpenAI-Beta'] = "assistants=v1"
      req.body = %Q[{
        "instructions": "#{interpolated['instructions']}",
        "name": "#{interpolated['name']}",
        "tools": #{interpolated['tools']},
        "model": "#{interpolated['model']}"
      }]

      # Send the request and print the response
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      self.update! options: self.options.deep_merge({ "assistant_id": JSON.parse(response.body)['id'] }) #save to response['id'] to database... update agent config after OpenAI handshake
      log_curl_output(response.code,response.body)
      #only really need to emit the assistant's response after run completes + any code/functions/documents created
      if interpolated['emit_events'] == 'true'
        create_event payload: response.body
      end
      #self.options['assistant_id'] = JSON.parse(response.body)['id']
      #save!
    end

    def create_thread()   #step 2-
      # Build the HTTP request to send the message
      uri = URI("https://api.openai.com/v1/threads")
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      req['Authorization'] = "Bearer #{interpolated['OPENAI_API_KEY'][0..-1]}"
      req['OpenAI-Beta'] = "assistants=v1"
      req.body = ''
      # Send the request and print the response
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end
      log_curl_output(response.code,response.body)
      if interpolated['emit_events'] == 'true'
        create_event payload: response.body
      end
      self.update! options: self.options.deep_merge({ "thread_id": JSON.parse(response.body)['id'] })
      #self.options['thread_id'] = JSON.parse(response.body)['id']
      #save!
    end

    def add_message()   #step 3-
      message = { content: interpolated['content'] }.to_json
      # Build the HTTP request to send the message
      uri = URI("https://api.openai.com/v1/threads/#{interpolated['thread_id']}/messages")
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      req['Authorization'] = "Bearer #{interpolated['OPENAI_API_KEY'][0..-1]}"
      req['OpenAI-Beta'] = "assistants=v1"
      request_body = {
        "role" => "user",
        "content" => "Can you solve the equation 3x+5=11?"
      }
      req.body = request_body.to_json

      # Send the request and print the response
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end
      log_curl_output(response.code,response.body)
      if interpolated['emit_events'] == 'true'
        create_event payload: response.body
      end
    end

    def run_assistant()   #step 4-
      # Build the HTTP request to send the message
      uri = URI("https://api.openai.com/v1/threads/#{interpolated['thread_id']}/runs")
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      req['Authorization'] = "Bearer #{interpolated['OPENAI_API_KEY'][0..-1]}"
      req['OpenAI-Beta'] = "assistants=v1"
      req.body = %Q[{
        "assistant_id": "#{interpolated['assistant_id']}",
        "instructions": "Please address the user as Jane Doe. The user has a premium account.",
        "tools": #{interpolated['tools']},
        "model": "#{interpolated['model']}"
      }]
      # Send the request and print the response
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end
      log_curl_output(response.code,response.body)
      if interpolated['emit_events'] == 'true'
        create_event payload: response.body
      end
      self.update! options: self.options.deep_merge({ "run_id": JSON.parse(response.body)['id'] })
      #self.options['run_id'] = JSON.parse(response.body)['id']
      save!
    end

    def check_status()   #step 5- see if queued run status has moved to completed
      # Build the HTTP request to send the message
      uri = URI("https://api.openai.com/v1/threads/#{interpolated['thread_id']}/runs/#{interpolated['run_id']}")
      req = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
      req['Authorization'] = "Bearer #{interpolated['OPENAI_API_KEY'][0..-1]}"
      req['OpenAI-Beta'] = "assistants=v1"
      # Send the request and print the response
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end
      log_curl_output(response.code,response.body)
      if interpolated['emit_events'] == 'true'
        create_event payload: response.body
      end
    end

    def display_message()   #step 6
      # Build the HTTP request to send the message
      uri = URI("https://api.openai.com/v1/threads/#{interpolated['thread_id']}/messages")
      req = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
      req['Authorization'] = "Bearer #{interpolated['OPENAI_API_KEY'][0..-1]}"
      req['OpenAI-Beta'] = "assistants=v1"
      # Send the request and print the response
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end
      log_curl_output(response.code,response.body)
      if interpolated['emit_events'] == 'true'
        create_event payload: response.body
      end
      #remove associated thread_id and run_id from this assistant_id
      #self.update! options: self.options.deep_merge({ "thread_id": nil, "run_id": nil  })
    end

    def trigger_action
      if options['assistant_id'].blank?
        create_assistant()  #should be triggered when new Agent instantiated with Role/Instructions/Tools/Files... user should never need to see id or set/unless they've preconfigured it elsewhere
      end
      '''
      thread1 = Thread.new do
        # Code to be executed in the first thread
          #add message, preAPI routing, run with tools, enable listener for that assisant_id completed response to that thread_id
      end
      thread2 = Thread.new do
        # Code to be executed in the second thread
          #add any more messages/reinstruct from user or assistants, listener for messages
      end
      # Wait for both threads to finish
      thread1.join
      thread2.join
      #send reply, shut down listener(s) for that thread, maybe move thread messages to vector db or something to learn from...
      '''
      #if interpolated['message']
        if interpolated['thread_id'].blank?
          create_thread() #recommended one thread per user started when they initiate conversation
        end
        add_message() #added via message objects, this'll be main functionality after configured, param, the real 'trigger_action'
        #can include files or images for processes via retrieval
        #can append messages in thread and list them
        if interpolated['run_id'].blank?
          #run required for assistant to respond to user
          run_assistant() #reads thread and uses tools (requires thread_id and assistant_id)
          #can pass new instructions to run, but that overrides previous ones
          #new run on same thread/window of conversation
        end
        #wait... a listener here? whole thing could be built as scenario from existing agents
        if interpolated['run_id']
          check_status()    #queued to completed
          display_message() #assistant may return a few messages
        end
        #I think different agents can respond to the same thread-->collaborate/call on other assistants to research/write software/documentation/testing
        #assistants as experts that add to thread becomes collecting lengths of collected information for whoever's interested... as in if you like this then you'll definitely like that
      end
    #end
  end
end
