# Slack Channel Archiver

A tool to help archive channels that haven't been used for a while.

## Running

You'll need the following pre-requisites.

* Ruby 2.5.1
* Bundler

You'll need a bot & user API tokens to run it. This can be specified in three ways, in order of priority:

1. Pass it as the trailing arguments, e.g. `bin/slack-channel-archiver 90 bot-api-token user-api-token`
1. Set it as env var `BOT_SLACK_API_TOKEN`/`USER_SLACK_API_TOKEN`, e.g. `BOT_SLACK_API_TOKEN=api-token USER_SLACK_API_TOKEN=another-token bin/slack-channel-archiver`
1. Set in `~/.slack-channel-archiver`, e.g. 
```
bot-api-token: an-api-token
user-api-token: another-api-token
```
    
You can obtain new API tokens by [creating a new App](https://api.slack.com/apps/new) in Slack. You'll need the scopes:
* `bot`
* `chat:write:bot`
* `channels:write`
* `channels:read`
* `channels:history`.

Note that channels will be marked as archived by the user who installed the app, as Slack doesn't allow bots to archive channels.

Usage:

    bin/slack-channel-archiver [inactivity-period = 90 days] [bot-api-token] [user-api-token]

On the first run it'll install dependencies, which may be a bit noisy.

Due to rate limits on the Slack side it'll run quite slowly - about 1 channel/second will be tested.
