# Slack Channel Archiver

A simple tool to help archive public channels that haven't been used for a while.

## Requirements

The following pre-requisites are required.

* [Ruby](https://www.ruby-lang.org/) 3.2.2
* [Bundler](https://bundler.io/)

This has only been tested in *nix environment (e.g. MacOS/Linux) although there's nothing tying it to these platforms.

You'll also require `bot` and `user` API tokens from Slack. You can obtain new API tokens by [creating a new App](https://api.slack.com/apps/new) in Slack. The token must have the following scopes:
* `bot`
* `chat:write:bot`
* `channels:write`
* `channels:read`
* `channels:history`.

## Configuration

### API Tokens

The `bot` and `user` API tokens can be specified in three ways, in order of priority:

1. Pass it as the trailing arguments, e.g. `bin/slack-channel-archiver 90 bot-api-token user-api-token`
1. Set it as env var `BOT_SLACK_API_TOKEN`/`USER_SLACK_API_TOKEN`, e.g. `BOT_SLACK_API_TOKEN=api-token USER_SLACK_API_TOKEN=another-token bin/slack-channel-archiver`
1. Set in `~/.slack-channel-archiver`, e.g. 
```
bot-api-token: an-api-token
user-api-token: another-api-token
```

### Configuration File

You can use the following configuration options in `~/.slack-channel-archiver`:

| Name | Type | Description |
| --- | --- | --- |
| bot-api-token | string | Slack bot API token, as described above |
| user-api-token | string | Slack user API token, as described above |
| ignored-channel-names | list of strings | Names of channels that should never be archived, even if they match the archive criteria |

For example:
```
bot-api-token: xoxb-a-bot-api-token
user-api-token: xoxp-a-user-api-token
ignored-channel-names:
- channel1
- channel2
```

## Running

Usage:

    bin/slack-channel-archiver [inactivity-period = 90 days] [bot-api-token] [user-api-token]

On the first run it'll install dependencies, which may be a bit noisy.

Due to rate limits on the Slack side it'll run quite slowly - about 1 channel/second will be tested. Also please note that channels will be marked as archived by the user who installed the app, as Slack doesn't allow bots to archive channels.

## Support

Support is on a best-effort basis. We'll endeavour to keep it in a good state and to respond to any issues/requests, but it works nicely for our purposes and is unlikely to see any major feature enhancements.

## Licencing 

This code is licenced under an MIT licence as described in [LICENSE](LICENSE).

Copyright &copy; 2018-2022 Springer Nature Ltd.
