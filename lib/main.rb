require 'yaml'
require 'slack'

class SlackChannelArchiver

    def initialize(bot_api_token, user_api_token)
        @client = Slack::Web::Client.new(token: bot_api_token)
        @client.auth_test

        @user_client = Slack::Web::Client.new(token: user_api_token)
        @user_client.auth_test
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
            last_messages = @user_client.channels_history(channel: channel.id, count: 1)
            if last_messages.messages.empty?
                puts "x Channel #{channel.name} is older than #{number_of_days} and has no messages"
                @client.chat_postMessage(channel: channel.id, text: "This channel has had no new messages in #{number_of_days} and will hence be archived - any queries, please see #slack-admin")
                @user_client.channels_archive(channel: channel.id)
                archived = true

            elsif days_ago(last_messages.messages.first.ts.to_d) > number_of_days
                puts "x Channel #{channel.name} is older than #{number_of_days} days and has had no messages in at least #{number_of_days} days"
                @client.chat_postMessage(channel: channel.id, text: "This channel is older than #{number_of_days} days and has no messages, and will hence be archived - any queries, please see #slack-admin")
                @user_client.channels_archive(channel: channel.id)
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
        bot_api_token, user_api_token = read_api_token(args[1], args[2])
        if number_of_days.nil? || bot_api_token.nil? || user_api_token.nil?
            $stderr.puts "Usage: $0 [number-of-days=#{DEFAULT_NUMBER_OF_DAYS}] [bot-api-token] [user-api-token]"
            $stderr.puts "Alternately you may specify the API token in ~/.slack-channel-archiver as 'api-token', or via envs BOT_SLACK_API_TOKEN / USER_SLACK_API_TOKEN"
            exit(1)
        end

        puts "Channels that have existed but have had no new messages for at least #{number_of_days} days will be archived"
        puts "Please note only one channel will be checked per second due to Slack API rate limits"

        slack_channel_archiver = SlackChannelArchiver.new(bot_api_token, user_api_token)
        archived_count, total_channels = slack_channel_archiver.archive_channels_inactive_for(number_of_days)

        puts "#{archived_count} of #{total_channels} channels were archived"
    end

    private

    DEFAULT_NUMBER_OF_DAYS = 90

    def read_api_token(bot_api_token_arg, user_api_token_arg)
        bot_api_token = bot_api_token_arg || ENV['BOT_SLACK_API_TOKEN']
        user_api_token = user_api_token_arg || ENV['USER_SLACK_API_TOKEN']

        if (bot_api_token.nil? || user_api_token.nil?) && File.exists?("#{Dir.home}/.slack-channel-archiver")
            config = YAML.load_file("#{Dir.home}/.slack-channel-archiver")
            bot_api_token = bot_api_token || config['bot-api-token']
            user_api_token = user_api_token || config['user-api-token']
        end

        [bot_api_token, user_api_token]
    end

end

Launcher.new(ARGV) if __FILE__ == $0
