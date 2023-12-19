#https://github.com/octree-gva/huginn_agents
module Agents
  class Harvest < Agent
    include FormConfigurable
    default_schedule '12h'
    gem_dependency_check { defined?(Harvesting::Client) }
    cannot_receive_events!

    description <<-MD
      The Harvest API agent allows you to fetch harvest api and dispatch results.

      ### Authentication

      * `access_token`: Harvest api token
      * `account_id`: Harvest account id

      ### `model`
      Harvest API offers many api endpoints to queries it's models.
      `model` can be one of the following:

      * `clients`
      * `time_entries`
      * `tasks`
      * `projects`

      > N.B `invoices` are not yet supported.
    MD

    form_configurable :access_token, type: :text
    form_configurable :account_id, type: :text
    form_configurable :model, type: :array, values: %w(clients time_entries tasks projects)

    def default_options
      {
        access_token: "",
        account_id: "",
        model: "time_entries"
      }
    end

    def validate_options
      errors.add(:base, "can not connect to Harvest API: access_token is missing.") unless options["access_token"].present?
      errors.add(:base, "can not connect to Harvest API: account_id is missing.") unless options["account_id"].present?
    end

    def working?
      # Implement me! Maybe one of these next two lines would be a good fit?
      checked_without_error?
    end

   def check
      harvest_client = Harvesting::Client.new(
        access_token: interpolated["access_token"],
        account_id: interpolated["account_id"]
      )
      metas = {account: interpolated["account_id"], model: interpolated["model"]}
      case options["model"]
      when "clients"
        harvest_client.clients.each do |client|
          create_event payload: {
            metas: metas,
            data: client.as_json
          }
        end
      when "time_entries"
        harvest_client.time_entries.each do |time_entry|
          create_event payload: {
            metas: metas,
            data: time_entry.as_json
          }
        end
      when "tasks"
        harvest_client.tasks.each do |task|
          create_event payload: {
            metas: metas,
            data: task.as_json
          }
        end
      when "projects"
        harvest_client.projects.each do |project|
          create_event payload: {
            metas: metas,
            data: project.as_json
          }
        end
      end
   end
  end
end
