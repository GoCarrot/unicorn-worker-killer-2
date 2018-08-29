# frozen_string_literal: true

require 'unicorn'

require_relative 'worker-killer-2/oom'
require_relative 'worker-killer-2/max_requests'

module Unicorn
  module WorkerKiller
    # Kill the current process by telling it to send signals to itself. If the
    # process isn't killed after 5 QUIT signals, send 10 TERM signals. Finally,
    # send a KILL signal. A single signal is sent per request.
    #
    # @see http://unicorn.bogomips.org/SIGNALS.html
    def self.kill_self(logger, start_time)
      alive_sec = (Time.now - start_time).round
      worker_pid = Process.pid

      @kill_attempts ||= 0
      @kill_attempts += 1

      sig = :QUIT
      sig = :TERM if @kill_attempts > 10
      sig = :KILL if @kill_attempts > 15

      logger.warn "#{self} send SIG#{sig} (pid: #{worker_pid}) alive: #{alive_sec} sec (trial #{@kill_attempts})"
      Process.kill sig, worker_pid
    end

    def self.randomize(integer)
      Random.rand(integer.abs)
    end
  end
end
