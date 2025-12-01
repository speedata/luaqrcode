See the homepage at http://speedata.github.io/luaqrcode/ for more information.

Special thanks to all contributors. Everything helps: bug reports, patches etc.

License: 3-clause BSD license<br>
Usability status: mature, used in production<br>
Maintenance status: maintained (bug fixes)<br>

Part of the [speedata Publisher](https://www.speedata.de/).

## Development

### Running tests

A basic test suite is available and can be run with:

```sh
make test
```

This will execute the Lua test script provided in the repository and is intended to catch regressions and verify the behaviour of non-trivial functions. Contributions that change core logic should ideally extend or update these tests.

#### Black-box QR testcases

Black-box tests live in `qrblackbox.lua` and load sample data from `qrblackbox_data.lua`. Each test case is on a single line to make appending easy.

- Generate a new case: `lua qrblackbox.lua --generate "your text"`; this prints a ready-to-paste line.
- Append that line to the end of `qrblackbox_data.lua`.
- Run the tests: `lua qrblackbox.lua` or `make test`.

### Profiling / hotspot analysis

For performance work there is a small profiling script that can be invoked via:

```sh
make profile
```

This runs a simple benchmark/profiling setup to identify hotspots in typical usage scenarios. The results should be treated as a rough guide only, not as a precise or stable performance reference. They are mainly intended to help decide where optimizations are worthwhile and to avoid micro-optimizations in non-critical code paths.

