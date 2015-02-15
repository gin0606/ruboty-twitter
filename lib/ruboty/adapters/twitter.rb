require "active_support/core_ext/object/try"
require "mem"
require "twitter"

module Ruboty
  module Adapters
    class Twitter < Base
      include Mem

      env :TWITTER_CONSUMER_KEY, "Twitter consumer key (a.k.a. API key)"
      env :TWITTER_CONSUMER_SECRET, "Twitter consumer secret (a.k.a. API secret)"
      env :TWITTER_ACCESS_TOKEN, "Twitter access token"
      env :TWITTER_ACCESS_TOKEN_SECRET, "Twitter access token secret"

      def run
        Ruboty.logger.debug("#{self.class}##{__method__} started")
        abortable
        listen
        Ruboty.logger.debug("#{self.class}##{__method__} finished")
      end

      def say(message)
        client.update(message[:body], in_reply_to_status_id: message[:original][:tweet].try(:id))
      end

      private

      def listen
        stream.user do |tweet|
          case tweet
          when ::Twitter::Tweet
            Ruboty.logger.debug("@#{tweet.user.screen_name}: #{tweet.text}")
            robot.receive(
              body: tweet.text,
              from: tweet.user.screen_name,
              tweet: tweet
            )
          end
        end
      end

      def client
        ::Twitter::REST::Client.new do |config|
          config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
          config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
          config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
          config.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
        end
      end
      memoize :client

      def stream
        ::Twitter::Streaming::Client.new do |config|
          config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
          config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
          config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
          config.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
        end
      end
      memoize :stream

      def abortable
        Thread.abort_on_exception = true
      end
    end
  end
end
