require 'logger'

module PayPal::SDK::Core

  # Include Logging module to provide logger functionality.
  # == Configure logger
  #   Logging.logger = Logger.new(STDERR)
  #
  # == Example
  #   include Logger
  #   logger.info "Debug message"
  module Logging

    # Get logger object
    def logger
      @logger ||= Logging.logger
    end

    def log_event(message, &block)
      start_time = Time.now
      block.call
    ensure
      logger.info {sprintf("[%.3fs] %s", Time.now - start_time, message)}
    end

    class << self

      # Get or Create configured logger based on the default environment configuration
      def logger
        @logger ||= Logger.new(STDERR)
      end

      # Set logger directly and clear the loggers cache.
      # === Attributes
      # * <tt>logger</tt> -- Logger object
      # === Example
      #   Logging.logger = Logger.new(STDERR)
      def logger=(logger)
        @logger = logger
        if Config.config.mode.eql? 'live' and @logger.level == Logger::DEBUG
          @logger.warn "DEBUG log level not allowed in sandbox mode for security of confidential information. Changing log level to INFO..."
          @logger.level = Logger::INFO
        end
      end

    end
  end

end

