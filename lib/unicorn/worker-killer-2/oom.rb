# frozen_string_literal: true

require 'get_process_mem'

module Unicorn
  module WorkerKiller
    module Oom
      module MonkeyPatch
        def process_client(client)
          super(client) # Unicorn::HttpServer#process_client

          return if @_worker_memory_limit_min.zero? &&
                    @_worker_memory_limit_max.zero?

          @_worker_check_count ||= 0
          @_worker_check_count += 1

          return unless (@_worker_check_count % @_worker_check_cycle).zero?

          mem = GetProcessMem.new
          rss = if mem.respond_to?(:private_bytes)
                  mem.private_bytes
                else
                  mem.bytes
                end

          logger.info "#{self}: worker (pid: #{Process.pid}) using #{rss} bytes." if @_verbose
          return if rss < @_worker_memory_limit

          logger.warn "#{self}: worker (pid: #{Process.pid}) exceeds memory limit (#{rss} bytes > #{@_worker_memory_limit} bytes)"
          WorkerKiller.kill_self(logger, @_worker_process_start)
        end
      end

      def self.monkey_patch(opts = {})
        min = opts[:memory_limit_min] || (1024**3)
        max = opts[:memory_limit_max] || 2 * (1024**3)
        check_cycle = opts[:check_cycle] || 16
        verbose = opts[:verbose] || false

        ObjectSpace.each_object(Unicorn::HttpServer) do |s|
          s.extend(MonkeyPatch)

          s.instance_variable_set(:@_worker_process_start, WorkerKiller.now)

          s.instance_variable_set(:@_worker_memory_limit_min, min)
          s.instance_variable_set(:@_worker_memory_limit_max, max)
          s.instance_variable_set(:@_worker_check_cycle, check_cycle)
          s.instance_variable_set(:@_verbose, verbose)

          r = WorkerKiller.randomize(max - min + 1)
          s.instance_variable_set(:@_worker_memory_limit, min + r)
        end
      end
    end
  end
end
