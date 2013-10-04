# encoding: utf-8
require 'json'
require 'socket'

module Backup
  module Notifier
    class Sensu < Base

      ##
      # The Sensu client port
      attr_accessor :port

      ##
      # The Sensu check name
      attr_accessor :name

      ##
      # The Sensu check handler to use
      attr_accessor :handler

      def initialize(model, &block)
        super
        instance_eval(&block) if block_given?

        @port     ||= 3030
        @name     ||= "Backup Results"
        @handler  ||= ["default"]
      end

      private

      ##
      # Notify the user of the backup operation results.
      #
      # `status` indicates one of the following:
      #
      # `:success`
      # : The backup completed successfully.
      # : Notification will be sent if `on_success` is `true`.
      #
      # `:warning`
      # : The backup completed successfully, but warnings were logged.
      # : Notification will be sent if `on_warning` or `on_success` is `true`.
      #
      # `:failure`
      # : The backup operation failed.
      # : Notification will be sent if `on_warning` or `on_success` is `true`.
      #
      def notify!(status)
        tag, level = case status
                     when :success then ['[Backup::Success]', 0]
                     when :warning then ['[Backup::Warning]', 1]
                     when :failure then ['[Backup::Failure]', 2]
                     end
        message = "#{ tag } #{ model.label } (#{ model.trigger })"
        send_message(message, level)
      end

      # Hipchat::Client will raise an error if unsuccessful.
      def send_message(msg, status)
        json = {
          "name"    => @name,
          "output"  => msg,
          "status"  => status,
          "handler" => @handler
        }.to_json
        s = UDPSocket.new
        s.send(json, 0, '127.0.0.1', 3030)
        s.close
      end
    end
  end
end
