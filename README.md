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

## Notes On Permissions

This implementation requires raw sockets. On Linux this means that you either need to run as root or to set the correct capability on the executable. You can do this with:
```
setcap cap_net_raw=ep executable-name
```
If you lack the capability the code will throw an `Errno` exception with `#e == LibC::EPERM`

## Contributing

Contributions are welcome. Please fork the repository, commit changes on a branch, and then open a pull request.
