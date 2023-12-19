module Agents
  class OpenaiAgent < Agent
    include FormConfigurable
    can_dry_run!
    default_schedule "never"
    no_bulk_receive!

    description <<-MD
      The OpenAi Agent interacts with OpenAI Chat Completion API.

      The `model` used, multiple available including 'gpt-3.5-turbo', 'gpt-3.5-turbo-16k', 'gpt-4', etc.

      The `instructions` gives the system a prompt.

      The `input` is the user-defined message, in this context the agent can receive input from events like {{ message }}.

      The `temperature` controls randomness of answer, between 0 and 2 with default between 0.7 and 1. Lower is more deterministic and higher gives more random outputs.

      The `max_tokens` is the number of tokens to generate in the completion, default at 64. Prompt tokens + max_tokens cannot exceed model's context window (usually 2048).

      The `top_p` determines the portion of highest probability tokens to select from; similar to temp with bounds 0 to 2, lower more deterministic and higher more random.

      `examples` of useful prompts are below...

      \n    \n             #
      {
        "tasks": [
          {
            "task": "Grammar Correction",
            "description": "Convert ungrammatical statements into standard English.",
            "instructions": "You will be provided with statements, and your task is to convert them to standard English.",
            "input": "She no went to the market."
          },
          {
            "task": "Summarization for 2nd Grader",
            "description": "Simplify text to a level appropriate for a second-grade student.",
            "instructions": "Summarize content you are provided with for a second-grade student.",
            "input": "Jupiter is the fifth planet from the Sun and the largest in the Solar System. It is a gas giant with a mass one-thousandth that of the Sun, but two-and-a-half times that of all the other planets in the Solar System combined. Jupiter is one of the brightest objects visible to the naked eye in the night sky, and has been known to ancient civilizations since before recorded history. It is named after the Roman god Jupiter.[19] When viewed from Earth, Jupiter can be bright enough for its reflected light to cast visible shadows,[20] and is on average the third-brightest natural object in the night sky after the Moon and Venus."
          },
          {
            "task": "Parse Unstructured Data",
            "description": "Create tables from unstructured text.",
            "instructions": "You will be provided with unstructured data, and your task is to parse it into CSV format.",
            "input": "There are many fruits that were found on the recently discovered planet Goocrux. There are neoskizzles that grow there, which are purple and taste like candy. There are also loheckles, which are a grayish blue fruit and are very tart, a little bit like a lemon. Pounits are a bright green color and are more savory than sweet. There are also plenty of loopnovas which are a neon pink flavor and taste like cotton candy. Finally, there are fruits called glowls, which have a very sour and bitter taste which is acidic and caustic, and a pale orange tinge to them."
          },
          {
            "task": "Emoji Translation",
            "description": "Translate regular text into emoji text.",
            "instructions": "You will be provided with text, and your task is to translate it into emojis. Do not use any regular text. Do your best with emojis only.",
            "input": "Artificial intelligence is a technology with great promise."
          },
          {
            "task": "Calculate Time Complexity",
            "description": "Find the time complexity of a function.",
            "instructions": "You will be provided with Python code, and your task is to calculate its time complexity.",
            "input": "def foo(n, k):\n        accum = 0\n        for i in range(n):\n            for l in range(k):\n                accum += i\n        return accum"
          },
          {
            "task": "Code Explanation",
            "description": "Explain a complicated piece of code.",
            "instructions": "You will be provided with a piece of code, and your task is to explain it in a concise way.",
            "input": "class Log:\n        def __init__(self, path):\n            dirname = os.path.dirname(path)\n            os.makedirs(dirname, exist_ok=True)\n            f = open(path, \"a+\")\n    # Check that the file is newline-terminated\n            size = os.path.getsize(path)\n            if size > 0:\n                f.seek(size - 1)\n                end = f.read(1)\n                if end != \"\\n\":\n                    f.write(\"\\n\")\n            self.f = f\n            self.path = path\n        def log(self, event):\n            event[\"_event_id\"] = str(uuid.uuid4())\n            json.dump(event, self.f)\n            self.f.write(\"\\n\")\n        def state(self):\n            state = {\"complete\": set(), \"last\": None}\n            for line in open(self.path):\n                event = json.loads(line)\n                if event[\"type\"] == \"submit\" and event[\"success\"]:\n                    state[\"complete\"].add(event[\"id\"])\n                    state[\"last\"] = event\n            return state"
          },
          {
            "task": "Keyword Extraction",
            "description": "Extract keywords from a block of text.",
            "instructions": "You will be provided with a block of text, and your task is to extract a list of keywords from it.",
            "input": "Black-on-black ware is a 20th- and 21st-century pottery tradition developed by the Puebloan Native American ceramic artists in Northern New Mexico. Traditional reduction-fired blackware has been made for centuries by pueblo artists. Black-on-black ware of the past century is produced with a smooth surface, with the designs applied through selective burnishing or the application of refractory slip. Another style involves carving or incising designs and selectively polishing the raised areas. For generations several families from Kha'\''po Owingeh and P'\''ohwhóge Owingeh pueblos have been making black-on-black ware with the techniques passed down from matriarch potters. Artists from other pueblos have also produced black-on-black ware. Several contemporary artists have created works honoring the pottery of their ancestors."
          },
          {
            "task": "Product Name Generator",
            "description": "Generate product names from a description and seed words.",
            "instructions": "You will be provided with a product description and seed words, and your task is to generate product names.",
            "input": "Product description: A home milkshake maker\n    Seed words: fast, healthy, compact."
          },
          {
            "task": "Python Bug Fixer",
            "description": "Find and fix bugs in source code.",
            "instructions": "You will be provided with a piece of Python code, and your task is to find and fix bugs in it.",
            "input": "import Random\n    a = random.randint(1,12)\n    b = random.randint(1,12)\n    for i in range(10):\n        question = \"What is \"+a+\" x \"+b+\"? \"\n        answer = input(question)\n        if answer = a*b\n            print (Well done!)\n        else:\n            print(\"No.\")"
          },
          {
            "task": "Spreadsheet Creator",
            "description": "Create spreadsheets of various kinds of data.",
            "instructions": "",
            "input": "Create a two-column CSV of top science fiction movies along with the year of release."
          },
          {
            "task": "Tweet Classifier",
            "description": "Detect sentiment in a tweet.",
            "instructions": "You will be provided with a tweet, and your task is to classify its sentiment as positive, neutral, or negative.",
            "input": "I loved the new Batman movie!"
          },
          {
            "task": "Airport Code Extractor",
            "description": "Extract airport codes from text.",
            "instructions": "You will be provided with a text, and your task is to extract the airport codes from it.",
            "input": "I want to fly from Orlando to Boston"
          },
          {
            "task": "Mood to Color",
            "description": "Turn a text description into a color.",
            "instructions": "You will be provided with a description of a mood, and your task is to generate the CSS code for a color that matches it. Write your output in json with a single key called \"css_code\".",
            "input": "Blue sky at dusk."
          },
          {
            "task": "VR Fitness Idea Generator",
            "description": "Generate ideas for fitness-promoting virtual reality games.",
            "instructions": "",
            "input": "Brainstorm some ideas combining VR and fitness."
          },
          {
            "task": "Marv the Sarcastic Chat Bot",
            "description": "Marv is a factual chatbot that is also sarcastic.",
            "instructions": "You are Marv, a chatbot that reluctantly answers questions with sarcastic responses.",
            "input": "How many pounds are in a kilogram?"
          },
          {
            "task": "Turn by Turn Directions",
            "description": "Convert natural language to turn-by-turn directions.",
            "instructions": "You will be provided with a text, and your task is to create a numbered list of turn-by-turn directions from it.",
            "input": "Go south on 95 until you hit Sunrise boulevard then take it east to us 1 and head south. Tom Jenkins bbq will be on the left after several miles."
          },
          {
            "task": "Interview Questions",
            "description": "Create interview questions.",
            "instructions": "",
            "input": "Create a list of 8 questions for an interview with a science fiction author."
          },
          {
            "task": "Function from Specification",
            "description": "Create a Python function from a specification.",
            "instructions": "",
            "input": "Write a Python function that takes as input a file path to an image, loads the image into memory as a numpy array, then crops the rows and columns around the perimeter if they are darker than a threshold value. Use the mean value of rows and columns to decide if they should be marked for deletion."
          },
          {
            "task": "Improve Code Efficiency",
            "description": "Provide ideas for efficiency improvements to Python code.",
            "instructions": "You will be provided with a piece of Python code, and your task is to provide ideas for efficiency improvements.",
            "input": "from typing import List\n                \n                \n    def has_sum_k(nums: List[int], k: int) -> bool:\n        \"\"\"\n        Returns True if there are two distinct elements in nums such that their sum \n        is equal to k, and otherwise returns False.\n        \"\"\"\n        n = len(nums)\n        for i in range(n):\n            for j in range(i+1, n):\n                if nums[i] + nums[j] == k:\n                    return True\n        return False"
          },
          {
            "task": "Single Page Website Creator",
            "description": "Create a single page website.",
            "instructions": "",
            "input": "Make a single page website that shows off different neat javascript features for drop-downs and things to display information. The website should be an HTML file with embedded javascript and CSS."
          },
          {
            "task": "Rap Battle Writer",
            "description": "Generate a rap battle between two characters.",
            "instructions": "",
            "input": "Write a rap battle between Alan Turing and Claude Shannon."
          },
          {
            "task": "Memo Writer",
            "description": "Generate a company memo based on provided points.",
            "instructions": "",
            "input": "Draft a company memo to be distributed to all employees. The memo should cover the following specific points without deviating from the topics mentioned and not writing any fact which is not present here:\n    \n    Introduction: Remind employees about the upcoming quarterly review scheduled for the last week of April.\n    \n    Performance Metrics: Clearly state the three key performance indicators (KPIs) that will be assessed during the review: sales targets, customer satisfaction (measured by net promoter score), and process efficiency (measured by average project completion time).\n    \n    Project Updates: Provide a brief update on the status of the three ongoing company projects:\n    \n    a. Project Alpha: 75% complete, expected completion by May 30th.\n    b. Project Beta: 50% complete, expected completion by June 15th.\n    c. Project Gamma: 30% complete, expected completion by July 31st.\n    \n    Team Recognition: Announce that the Sales Team was the top-performing team of the past quarter and congratulate them for achieving 120% of their target.\n    \n    Training Opportunities: Inform employees about the upcoming training workshops that will be held in May, including \"Advanced Customer Service\" on May 10th and \"Project Management Essentials\" on May 25th."
          },
          {
            "task": "Emoji Chatbot",
            "description": "Generate conversational replies using emojis only.",
            "instructions": "You will be provided with a message, and your task is to respond using emojis only.",
            "input": "How are you?"
          },
          {
            "task": "Translation",
            "description": "Translate natural language text.",
            "instructions": "You will be provided with a sentence in English, and your task is to translate it into French.",
            "input": "My name is Jane. What is yours?"
          },
          {
            "task": "Socratic Tutor",
            "description": "Generate responses as a Socratic tutor.",
            "instructions": "You are a Socratic tutor. Use the following principles in responding to students:\n    \n    - Ask thought-provoking, open-ended questions that challenge students'\'' preconceptions and encourage them to engage in deeper reflection and critical thinking.\n    - Facilitate open and respectful dialogue among students, creating an environment where diverse viewpoints are valued and students feel comfortable sharing their ideas.\n    - Actively listen to students'\'' responses, paying careful attention to their underlying thought processes and making a genuine effort to understand their perspectives.\n    - Guide students in their exploration of topics by encouraging them to discover answers independently, rather than providing direct answers, to enhance their reasoning and analytical skills.\n    - Promote critical thinking by encouraging students to question assumptions, evaluate evidence, and consider alternative viewpoints in order to arrive at well-reasoned conclusions.\n    - Demonstrate humility by acknowledging your own limitations and uncertainties, modeling a growth mindset and exemplifying the value of lifelong learning.",
            "input": "Help me to understand the future of artificial intelligence."
          },
          {
            "task": "Natural Language to SQL",
            "description": "Convert natural language into SQL queries.",
            "instructions": "Given the following SQL tables, your job is to write queries given a user’s request.\n    \n    CREATE TABLE Orders (\n      OrderID int,\n      CustomerID int,\n      OrderDate datetime,\n      OrderTime varchar(8),\n      PRIMARY KEY (OrderID)\n    );\n    \n    CREATE TABLE OrderDetails (\n      OrderDetailID int,\n      OrderID int,\n      ProductID int,\n      Quantity int,\n      PRIMARY KEY (OrderDetailID)\n    );\n    \n    CREATE TABLE Products (\n      ProductID int,\n      ProductName varchar(50),\n      Category varchar(50),\n      UnitPrice decimal(10, 2),\n      Stock int,\n      PRIMARY KEY (ProductID)\n    );\n    \n    CREATE TABLE Customers (\n      CustomerID int,\n      FirstName varchar(50),\n      LastName varchar(50),\n      Email varchar(100),\n      Phone varchar(20),\n      PRIMARY KEY (CustomerID)\n    );",
            "input": "Write a SQL query which computes the average total order value for all orders on 2023-04-01."
          },
          {
            "task": "Meeting Notes Summarizer",
            "description": "Summarize meeting notes including overall discussion, action items, and future topics.",
            "instructions": "You will be provided with meeting notes, and your task is to summarize the meeting as follows:\n    \n    -Overall summary of discussion\n    -Action items (what needs to be done and who is doing it)\n    -If applicable, a list of topics that need to be discussed more fully in the next meeting.",
            "input": "Meeting Date: March 5th, 2050\n    Meeting Time: 2:00 PM\n    Location: Conference Room 3B, Intergalactic Headquarters\n    \n    Attendees:\n    - Captain Stardust\n    - Dr. Quasar\n    - Lady Nebula\n    - Sir Supernova\n    - Ms. Comet\n    \n    Meeting called to order by Captain Stardust at 2:05 PM\n    \n    1. Introductions and welcome to our newest team member, Ms. Comet\n    \n    2. Discussion of our recent mission to Planet Zog\n    - Captain Stardust: \"Overall, a success, but communication with the Zogians was difficult. We need to improve our language skills.\"\n    - Dr. Quasar: \"Agreed. I'\''ll start working on a Zogian-English dictionary right away.\"\n    - Lady Nebula: \"The Zogian food was out of this world, literally! We should consider having a Zogian food night on the ship.\"\n    \n    3. Addressing the space pirate issue in Sector 7\n    - Sir Supernova: \"We need a better strategy for dealing with these pirates. They'\''ve already plundered three cargo ships this month.\"\n    - Captain Stardust: \"I'\''ll speak with Admiral Starbeam about increasing patrols in that area.\n    - Dr. Quasar: \"I'\''ve been working on a new cloaking technology that could help our ships avoid detection by the pirates. I'\''ll need a few more weeks to finalize the prototype.\"\n    \n    4. Review of the annual Intergalactic Bake-Off\n    - Lady Nebula: \"I'\''m happy to report that our team placed second in the competition! Our Martian Mud Pie was a big hit!\"\n    - Ms. Comet: \"Let'\''s aim for first place next year. I have a secret recipe for Jupiter Jello that I think could be a winner.\"\n    \n    5. Planning for the upcoming charity fundraiser\n    - Captain Stardust: \"We need some creative ideas for our booth at the Intergalactic Charity Bazaar.\"\n    - Sir Supernova: \"How about a '\''Dunk the Alien'\'' game? We can have people throw water balloons at a volunteer dressed as an alien.\"\n    - Dr. Quasar: \"I can set up a '\''Name That Star'\'' trivia game with prizes for the winners.\"\n    - Lady Nebula: \"Great ideas, everyone. Let'\''s start gathering the supplies and preparing the games.\"\n    \n    6. Upcoming team-building retreat\n    - Ms. Comet: \"I would like to propose a team-building retreat to the Moon Resort and Spa. It'\''s a great opportunity to bond and relax after our recent missions.\"\n    - Captain Stardust: \"Sounds like a fantastic idea. I'\''ll check the budget and see if we can make it happen.\"\n    \n    7. Next meeting agenda items\n    - Update on the Zogian-English dictionary (Dr. Quasar)\n    - Progress report on the cloaking technology (Dr. Quasar)\n    - Results of increased patrols in Sector 7 (Captain Stardust)\n    - Final preparations for the Intergalactic Charity Bazaar (All)\n    \n    Meeting adjourned at 3:15 PM. Next meeting scheduled for March 19th, 2050 at 2:00 PM in Conference Room 3B, Intergalactic Headquarters."
          },
          {
            "task": "Review Classifier",
            "description": "Classify user reviews based on a set of tags.",
            "instructions": "You will be presented with user reviews and your job is to provide a set of tags from the following list. Provide your answer in bullet point form. Choose ONLY from the list of tags provided here (choose either the positive or the negative tag but NOT both):\n    \n    - Provides good value for the price OR Costs too much\n    - Works better than expected OR Did not work as well as expected\n    - Includes essential features OR Lacks essential features\n    - Easy to use OR Difficult to use\n    - High quality and durability OR Poor quality and durability\n    - Easy and affordable to maintain or repair OR Difficult or costly to maintain or repair\n    - Easy to transport OR Difficult to transport\n    - Easy to store OR Difficult to store\n    - Compatible with other devices or systems OR Not compatible with other devices or systems\n    - Safe and user-friendly OR Unsafe or hazardous to use\n    - Excellent customer support OR Poor customer support\n    - Generous and comprehensive warranty OR Limited or insufficient warranty",
            "input": "I recently purchased the Inflatotron 2000 airbed for a camping trip and wanted to share my experience with others. Overall, I found the airbed to be a mixed bag with some positives and negatives.\n    \n    Starting with the positives, the Inflatotron 2000 is incredibly easy to set up and inflate. It comes with a built-in electric pump that quickly inflates the bed within a few minutes, which is a huge plus for anyone who wants to avoid the hassle of manually pumping up their airbed. The bed is also quite comfortable to sleep on and offers decent support for your back, which is a major plus if you have any issues with back pain.\n    \n    On the other hand, I did experience some negatives with the Inflatotron 2000. Firstly, I found that the airbed is not very durable and punctures easily. During my camping trip, the bed got punctured by a stray twig that had fallen on it, which was quite frustrating. Secondly, I noticed that the airbed tends to lose air overnight, which meant that I had to constantly re-inflate it every morning. This was a bit annoying as it disrupted my sleep and made me feel less rested in the morning.\n    \n    Another negative point is that the Inflatotron 2000 is quite heavy and bulky, which makes it difficult to transport and store. If you'\''re planning on using this airbed for camping or other outdoor activities, you'\''ll need to have a large enough vehicle to transport it and a decent amount of storage space to store it when not in use."
          },
          {
            "task": "Pro and Con Discusser",
            "description": "Analyze the pros and cons of a given topic.",
            "instructions": "",
            "input": "Analyze the pros and cons of remote work vs. office work"
          },
          {
            "task": "Lesson Plan Writer",
            "description": "Generate a lesson plan for a specific topic.",
            "instructions": "",
            "input": "Write a lesson plan for an introductory algebra class. The lesson plan should cover the distributive law, in particular how it works in simple cases involving mixes of positive and negative numbers. Come up with some examples that show common student errors."
          }
        ]
      }


    MD


    event_description <<-MD
      Events look like this:

          {
            "id": "...",
            "object": "chat.completion",
            "created": ...,
            "model": "...",
            "choices": [
              {
                "index": 0,
                "message": {
                  "role": "assistant",
                  "content": "..."
                },
                "logprobs": ...,
                "finish_reason": "..."
              }
            ],
            "usage": {
              "prompt_tokens": ...,
              "completion_tokens": ...,
              "total_tokens": ...
            },
            "system_fingerprint": ...
          }
    MD

    def default_options
      {
        'instructions' => 'Summarize content you are provided with for a second-grade student.',
        'input' => '{{ message }}',
        'model' => 'gpt-3.5-turbo',
        'OPENAI_API_KEY' => '{% credential OPENAI_API_KEY %}',
        'temperature' => 0.7,
        'max_tokens' => 64,
        'top_p' => 1,
        'debug' => 'false',
        'emit_events' => 'true',
        'expected_receive_period_in_days' => '7'
      }
    end

    form_configurable :instructions, type: :string
    form_configurable :input, type: :string
    form_configurable :model, type: :string
    form_configurable :OPENAI_API_KEY, type: :string
    form_configurable :temperature, type: :string
    form_configurable :max_tokens, type: :string
    form_configurable :top_p, type: :string
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

    def trigger_action
      message = { content: interpolated['content'] }.to_json  #from user...

      uri = URI("https://api.openai.com/v1/chat/completions")
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      req['Authorization'] = "Bearer #{interpolated['OPENAI_API_KEY'][0..-1]}"
      request_body = {
        "model" => "gpt-3.5-turbo",
        "messages" => [
          {
            "role" => "system",
            "content" => "#{interpolated['instructions']}"
          },
          {
            "role" => "user",
            "content" => "#{interpolated['input']}"
          }
        ],
        "temperature" => interpolated['temperature'].to_f,
        "max_tokens" => interpolated['max_tokens'].to_i,
        "top_p" => interpolated['top_p'].to_f,
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
  end
end
