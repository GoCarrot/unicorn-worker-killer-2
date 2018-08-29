# unicorn-worker-killer 2

This is a reimplementation of https://github.com/kzk/unicorn-worker-killer.

It's a lot faster because it doesn't pretend to be a middleware, and doesn't iterate over `ObjectSpace` for every request. Instead, you set it up in Unicorn's `after_fork` handler, like so;

```ruby
after_fork do |_server, _worker|
  # Restart a Unicorn process when it uses more than 192MB.
  Unicorn::WorkerKiller::Oom.monkey_patch(
    memory_limit_min: 192 * (1024**2),
    memory_limit_max: 256 * (1024**2),
    check_cycle: 128, verbose: true
  )

  # Restart Unicorn workers after about 5000 requests:
  Unicorn::WorkerKiller::MaxRequests.monkey_patch(
    max_requests_min: 5000,
    max_requests_max: 6000,
    verbose: true
  )
end
```

This is measurably faster; I tested an app before adding any killer at about 7100 requests/second. Adding the original killer slows it down to around 1100 requests/second. This one barely has any impact and the app still manages around 7000 requests/second.


It's horrible and hacky and monkeypatches Unicorn, but then again so did the original one.

It has no tests but neither did the original one.
