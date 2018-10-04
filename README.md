# Slack Channel Archiver

A tool to help archive channels that haven't been used for a while.

## Running

You'll need the following pre-requisites.

* Ruby 2.5.1
* Bundler

You'll need an API token  to run it. This can be specified in three ways, in order of priority:

1. Pass it as the second argument, e.g. `bin/slack-channel-archiver 90 api-token`
1. Set it as env var `SLACK_API_TOKEN`, e.g. `SLACK_API_TOKEN=api-token bin/slack-channel-archiver`
1. Set in `~/.slack-channel-archiver`, e.g. `api-token: an-api-token`
    
You can obtain a new API token by [creating a new Bot Integration](https://my.slack.com/services/new/bot) in Slack.

Usage:

    bin/slack-channel-archiver [inactivity-period = 90 days] [api-token]

On the first run it'll install dependencies, which may be a bit noisy.
