require 'yaml'
require 'slack'

class SlackChannelArchiver

    def initialize(bot_api_token, user_api_token, ignored_channel_names = nil)
        @client = Slack::Web::Client.new(token: bot_api_token)
        @client.auth_test

        @user_client = Slack::Web::Client.new(token: user_api_token)
        @user_client.auth_test

        @ignored_channel_names = ignored_channel_names || []
    end

    def archive_channels_inactive_for(number_of_days)
        channel_count = 0
        archived_count = 0

        @client.conversations_list(exclude_archived: true, limit: 100) do |response|
            response.channels.each do |current_channel|
                channel_count += 1
                archived_count += 1 if archive_channel_if_inactive_for(number_of_days, current_channel)
                sleep(1)
            end
        end

        [archived_count, channel_count]
    end

    private

    def archive_channel(channel_id, channel_name, archive_message)
        if @ignored_channel_names.include?(channel_name)
            puts "- Channel #{channel_name} is in the ignore list"
            false
        else
            puts "x Channel #{channel_name} will be archived: #{archive_message}"

            begin
                @client.chat_postMessage(channel: channel_id, text: archive_message) unless archive_message.nil?
                @user_client.conversations_archive(channel: channel_id)
                true
            rescue Slack::Web::Api::Errors::RestrictedAction
                puts "e Channel #{channel_name} could not be archived due to limited posted permissions"
                false
            end
        end
    end

    def archive_channel_if_inactive_for(number_of_days, channel)
        if @ignored_channel_names.include?(channel.name)
            puts "- Channel #{channel.name} is in the ignore list"
            false
        elsif days_ago(Time.at(channel.created)) > number_of_days
            archived = false
            done = false
            while !done do
                begin
                    last_messages = @user_client.conversations_history(channel: channel.id, count: 1)
                    if last_messages.messages.empty?
                        archived = archive_channel(channel.id, channel.name, "This channel is older than #{number_of_days} days and has no messages, and will hence be archived. You can unarchive it if this is not appropriate.")

                    elsif days_ago(last_messages.messages.first.ts.to_f) > number_of_days
                        archived = archive_channel(channel.id, channel.name, "This channel has had no new messages in #{number_of_days} days and will hence be archived. You can unarchive it if this is not appropriate.")

                    else
                        puts "- Channel #{channel.name} is in regular use"
                    end
                    done = true
                rescue Slack::Web::Api::Errors::TooManyRequestsError
                    puts "e Request limit exceeded; waiting 30 seconds..."
                    sleep(31)
                end
            end
            archived
        else
            puts "- Channel #{channel.name} is newer than #{number_of_days} days"
            false
        end
    end

    def days_ago(time)
        (Time.now - time).to_i / 86400
    end

end

class Launcher

    def initialize(args)
        number_of_days = (args[0] || DEFAULT_NUMBER_OF_DAYS).to_i
        config = read_config()
        bot_api_token, user_api_token = read_api_token(args[1], args[2], config)
        if number_of_days.nil? || bot_api_token.nil? || user_api_token.nil?
            $stderr.puts "Usage: #{$0} [number-of-days=#{DEFAULT_NUMBER_OF_DAYS}] [bot-api-token] [user-api-token]"
            $stderr.puts "Alternately you may specify the API token in ~/.slack-channel-archiver as 'api-token', or via envs BOT_SLACK_API_TOKEN / USER_SLACK_API_TOKEN"
            exit(1)
        end

        puts "Channels that have existed but have had no new messages for at least #{number_of_days} days will be archived"
        puts "Please note only one channel will be checked per second due to Slack API rate limits"

        ignored_channel_names = config['ignored-channel-names']
        puts "The following channels will be ignored:\n * #{ignored_channel_names.join("\n * ")}" unless ignored_channel_names.nil? || ignored_channel_names.empty?

        slack_channel_archiver = SlackChannelArchiver.new(bot_api_token, user_api_token, ignored_channel_names)
        archived_count, total_channels = slack_channel_archiver.archive_channels_inactive_for(number_of_days)

        puts "#{archived_count} of #{total_channels} channels were archived"
    end

    private

    DEFAULT_NUMBER_OF_DAYS = 90

    def read_config
        if File.exist?("#{Dir.home}/.slack-channel-archiver")
            YAML.load_file("#{Dir.home}/.slack-channel-archiver")
        else
            {}
        end
    end

    def read_api_token(bot_api_token_arg, user_api_token_arg, config)
        bot_api_token = bot_api_token_arg || ENV['BOT_SLACK_API_TOKEN'] || config['bot-api-token']
        user_api_token = user_api_token_arg || ENV['USER_SLACK_API_TOKEN'] || config['user-api-token']

        [bot_api_token, user_api_token]
    end

end

Launcher.new(ARGV) if __FILE__ == $0
