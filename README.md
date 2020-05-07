[![Crystal Version](https://img.shields.io/badge/crystal-0.34-blueviolet.svg?longCache=true&style=for-the-badge)](https://crystal-lang.org/)

# icmp.cr

An implementation of ICMP Ping in Crystal.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  icmp:
    github: robacarp/icmp.cr
```

## Usage

```crystal
require "icmp"

statistics = ICMP::Ping.new("8.8.8.8").ping(count: 3) do |request|
  puts "#{request.sequence} #{request.status} took #{request.roundtrip_time}ms"
end
p statistics
```

Outputs:
```
0 valid_response took 30ms
1 valid_response took 29ms
2 valid_response took 29ms
{count: 3, success: 3, fail: 0, average_response: 29.333333333333332}
```

## Permissions

On linux, this ping implementation uses a raw IP socket, which can run into some permission issues. After compiling, if you run into the error message `failed to create socket:: Operation not permitted (Errno)`, the kernel is probably blocking you.

To get around this, either run as root/sudo, or use [`setcap`](https://linux.die.net/man/8/setcap) to award `cap_net_raw` to your executable.

You can do this with `setcap cap_net_raw=ep <executable-name>`.

See `man 7 capabilities` and `man 8 setcap` for more information.

Thanks to @jocata and @duraki for helping here.

## Contributing

Contributions are welcome. Please fork the repository, commit changes on a branch, and then open a pull request.
