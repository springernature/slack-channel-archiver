require 'yaml'

class SlackChannelArchiver

    def initialize(api_token)
        puts "API token is #{api_token}"
    end

end

class Launcher

    def initialize(args)
        api_token = read_api_token(args)
        if api_token.nil?
            $stderr.puts("Usage: $0 [api-token]")
            $stderr.puts("Alternately you may specify the API token in ~/.slack-channel-archiver as 'api-token', or via env car SLACK_API_TOKEN")
        end

        slack_channel_archiver = SlackChannelArchiver.new(api_token)
    end

    private

    def read_api_token(args)
        api_token = args.first

        api_token = ENV['SLACK_API_TOKEN'] if api_token.nil?

        if api_token.nil? && File.exists?("#{Dir.home}/.slack-channel-archiver")
            config = YAML.load_file("#{Dir.home}/.slack-channel-archiver")
            api_token = config['api-token']
        end

        api_token
    end

end

Launcher.new(ARGV) if __FILE__ == $0
