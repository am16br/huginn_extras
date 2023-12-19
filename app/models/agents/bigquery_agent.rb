#https://github.com/albertsun/huginn_bigquery_agent
require "google/cloud/bigquery"

module Agents
  class BigqueryAgent < Agent
    default_schedule '12h'

    can_dry_run!

    description <<-MD
      The Bigquery Agent queries Google BigQuery. This is not a free service and requires a Google Cloud account.

      This agent relies on service accounts for authentication, rather than oauth.

      Setup:

      1. Visit [the google api console](https://code.google.com/apis/console/b/0/)
      2. Use your existing project (or create a new one)
      3. APIs & Auth -> Enable BigQuery
      4. Credentials -> Create new Client ID -> Service Account
      5. Download the JSON keyfile and either save it to a path, ie: `/home/huginn/Huginn-5d12345678cd.json`, or copy the value of `private_key` from the file.
      6. Grant that service account access to the BigQuery datasets and tables you want to query.

      The JSON keyfile you downloaded earlier should look like this:
      <pre><code>{
        "type": "service_account",
        "project_id": "huginn-123123",
        "private_key_id": "6d6b476fc6ccdb31e0f171991e5528bb396ffbe4",
        "private_key": "-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----\\n",
        "client_email": "huginn@huginn-123123.iam.gserviceaccount.com",
        "client_id": "123123...123123",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://accounts.google.com/o/oauth2/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/huginn%40huginn-123123.iam.gserviceaccount.com"
      }</code></pre>

      Agent Configuration:

      `project_id` - The id of the Google Cloud project.

      `query` - The BigQuery query to run. [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) formatting is supported to run queries based on receiving events.

      `use_legacy` - Whether or not to use BigQuery legacy SQL or standard SQL. (Defaults to `false`)

      `max` - Maximum number of rows to return. Defaults to unlimited, but results are always [limited to 10 MB](https://googlecloudplatform.github.io/google-cloud-ruby/#/docs/google-cloud-bigquery/v0.27.0/google/cloud/bigquery/project).

      `timeout` - How long to wait for query to complete (in ms). Defaults to `10000`.

      `event_per_row` - Whether to create one Event per row returned, or one event with all rows as `results`. Defaults to `false`.

      <b>Authorization</b>

      `keyfile` - (String) The path (relative to where Huginn is running) to the JSON keyfile downloaded in step 5 above.

      Alternately, `keyfile` can be a hash:

      `keyfile` `private_key` - The private key (value of `private_key` from the downloaded file). [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) formatting is supported if you want to use a Credential.  (E.g., `{% credential google-bigquery-key %}`)

      `keyfile` `client_email` - The value of `client_email` from the downloaded file. Same as the service account email.
    MD

    event_description <<-MD
      {
        'results' => [
          {
            one row of result
          },
          {
            ...
          }
        ]
      }

      OR

      {
        one row of result
      }
    MD

    def default_options
      {
        'expected_update_period_in_days' => 2,
        'project_id' => '',
        'query' => """SELECT * FROM `project_id.dataset.table` WHERE condition='condition' LIMIT 10""",
        'keyfile' => {
          'private_key' => "{% credential google-bigquery-key %}",
          'client_email' => 'your-service-account-email@project.iam.gserviceaccount.com'
        },
        'use_legacy' => false,
        'event_per_row' => false
      }
    end

    def validate_options
      errors.add(:base, "expected_update_period_in_days is required") unless options['expected_update_period_in_days'].present?
    end

    def working?
      event_created_within?(options['expected_update_period_in_days']) && most_recent_event && most_recent_event.payload['success'] == true && !recent_error_logs?
    end

    def google_client
      # https://googlecloudplatform.github.io/google-cloud-ruby/#/docs/google-cloud-bigquery/v0.26.0/guides/authentication
      # http://googlecloudplatform.github.io/google-cloud-ruby/#/docs/google-cloud-bigquery/v0.26.0/google/cloud/bigquery
      # keyfile can be path or hash

      if interpolated['keyfile'].is_a?(String)
        @bigquery_client ||= Google::Cloud::Bigquery.new(
          project: interpolated['project_id'],
          keyfile: interpolated['keyfile']
        )
      elsif interpolated['keyfile'].is_a?(Hash)
        @bigquery_client ||= Google::Cloud::Bigquery.new(
          project: interpolated['project_id'],
          keyfile: {
            type: "service_account",
            private_key: interpolated['keyfile']['private_key'],
            client_email: interpolated['keyfile']['client_email'] # service_account_email
          }
        )
      end
    end

    def check
      query_opts = {}
      if options['legacy_sql'].present?
        query_opts[:legacy_sql] = options['legacy_sql']
      end
      if interpolated['max'].present?
        query_opts[:max] = interpolated['max']
      end
      if interpolated['timeout'].present?
        query_opts[:timeout] = interpolated['timeout']
      end

      # https://googlecloudplatform.github.io/google-cloud-ruby/#/docs/google-cloud-bigquery/v0.27.0/google/cloud/bigquery/project
      results = google_client.query(
          interpolated['query'],
          query_opts
        )

      if options[:event_per_row].presence
        results.all do |row|
          create_event :payload => row
        end
      else
        create_event :payload => {
          results: results.all.to_a
        }
      end
    end

#    def receive(incoming_events)
#    end
  end
end
