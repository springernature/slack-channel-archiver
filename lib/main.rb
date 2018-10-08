require 'yaml'
require 'slack'

class SlackChannelArchiver

    def initialize(api_token)
        Slack.configure do |config|
            config.token = api_token
        end

        @client = Slack::Web::Client.new
        @client.auth_test
    end

    def archive_channels_inactive_for(number_of_days)
        unarchived_public_channels = @client.channels_list(exclude_archived: true).channels

        archived_count = 0

        unarchived_public_channels.each do |current_channel|
            archived_count += 1 if archive_channel_if_inactive_for(number_of_days, current_channel)

            # channels_history is a tier 3 method, so we needs to limit acess to ~50 a minute - https://api.slack.com/docs/rate-limits#tier_t3
            sleep(1)
        end

        [archived_count, unarchived_public_channels.length]
    end

    private

    def archive_channel_if_inactive_for(number_of_days, channel)
        archived = false

        if days_ago(Time.at(channel.created)) > number_of_days        
            last_messages = @client.channels_history(channel: channel.id, count: 1)
            if last_messages.messages.empty?
                puts "x Channel #{channel.name} is older than #{number_of_days} and has no messages"
                @client.chat_postMessage(channel: channel.id, text: "This channel has had no new messages in #{number_of_days} and will hence be archived - any queries, please see #slack-admin")
                @client.channels_archive(channel: channel.id)
                archived = true

            elsif days_ago(last_messages.messages.first.ts.to_d) > number_of_days
                puts "x Channel #{channel.name} is older than #{number_of_days} days and has had no messages in at least #{number_of_days} days"
                @client.chat_postMessage(channel: channel.id, text: "This channel is older than #{number_of_days} days and has no messages, and will hence be archived - any queries, please see #slack-admin")
                @client.channels_archive(channel: channel.id)
                archived = true
            else
                puts "- Channel #{channel.name} is in regular use"
            end
        else
            puts "- Channel #{channel.name} is newer than #{number_of_days} days"
        end

        archived
    end

    def days_ago(time)
        (Time.now - time).to_i / 86400
    end

end

class Launcher

    def initialize(args)
        number_of_days = (args[0] || DEFAULT_NUMBER_OF_DAYS).to_i
        api_token = read_api_token(args[1])
        if number_of_days.nil? || api_token.nil?
            $stderr.puts "Usage: $0 [number-of-days=#{DEFAULT_NUMBER_OF_DAYS}] [api-token]"
            $stderr.puts "Alternately you may specify the API token in ~/.slack-channel-archiver as 'api-token', or via env car SLACK_API_TOKEN"
            exit(1)
        end

        puts "Channels that have existed but have had no new messages for at least #{number_of_days} days will be archived"
        puts "Please note only one channel will be checked per second due to Slack API rate limits"

        slack_channel_archiver = SlackChannelArchiver.new(api_token)
        archived_count, total_channels = slack_channel_archiver.archive_channels_inactive_for(number_of_days)

        puts "#{archived_count} of #{total_channels} channels were archived"
    end

    private

    DEFAULT_NUMBER_OF_DAYS = 90

    def read_api_token(api_token_arg)
        api_token = api_token_arg

        api_token = ENV['SLACK_API_TOKEN'] if api_token.nil?

        if api_token.nil? && File.exists?("#{Dir.home}/.slack-channel-archiver")
            config = YAML.load_file("#{Dir.home}/.slack-channel-archiver")
            api_token = config['api-token']
        end

        api_token
    end

end

Launcher.new(ARGV) if __FILE__ == $0
