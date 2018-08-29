# frozen_string_literal: true

module Unicorn
  module WorkerKiller
    module MaxRequests
      module MonkeyPatch
        def process_client(client)
          super(client) # Unicorn::HttpServer#process_client

          return if @_worker_max_requests_min.zero? &&
                    @_worker_max_requests_max.zero?

          logger.info "#{self}: worker (pid: #{Process.pid}) has #{@_worker_request_limit} left before being killed" if @_verbose

          @_worker_request_limit -= 1
          return if @_worker_request_limit.positive?

          logger.warn "#{self}: worker (pid: #{Process.pid}) exceeds max number of requests (limit: #{@_worker_max_requests})"
          WorkerKiller.kill_self(logger, @_worker_process_start)
        end
      end

      def self.monkey_patch(opts = {})
        min = opts[:max_requests_min] || 3072
        max = opts[:max_requests_max] || 4096
        verbose = opts[:verbose] || false

        ObjectSpace.each_object(HttpServer) do |s|
          s.extend(MonkeyPatch)

          s.instance_variable_set(:@_worker_process_start, WorkerKiller.now)

          s.instance_variable_set(:@_worker_max_requests_min, min)
          s.instance_variable_set(:@_worker_max_requests_max, max)
          s.instance_variable_set(:@_verbose, verbose)

          r = WorkerKiller.randomize(max - min + 1)
          s.instance_variable_set(:@_worker_request_limit, min + r)
        end
      end
    end
  end
end
