# URL Tracker

![urltracker demo](docs/demo/demo.gif)

> A command-line tool to check HTTP status codes and track redirects.

Github repo: [https://github.com/nalmeida/urltracker](https://github.com/nalmeida/urltracker)

## Overview

URL Tracker helps you analyze HTTP responses and redirects for single URLs or lists of URLs. Perfect for website maintenance, SEO auditing, and link checking.

### Features:

- Single URL status checking
- Batch URL processing from a txt file
- Redirect chain tracking
- CSV output for further analysis
- Basic authentication support
- Custom headers and cookies

> Since `v2.0.0` urltracker sends `GET` as default request method as some servers were returning `404` status instead of `200`.

> Since `v1.2.0` urltracker sends a custom header `User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3` instead of original `User-Agent: curl/7.54.1` to better emulate browser behaviour.

## Requirements

- Bash shell environment
- `curl` command-line tool
- `BATS` (Bash Automated Testing System) for running tests

## Installation

### Via Homebrew

```bash
brew tap nalmeida/urltracker
brew install urltracker
```

> [!NOTE]
> [URL Tracker Homebrew Formula](https://github.com/nalmeida/homebrew-urltracker)

### Via git clone 

1. Clone this repository:
```bash
git clone https://github.com/nalmeida/urltracker.git
cd urltracker
```

2. Make the script executable:
```bash
chmod +x urltracker
```

3. (Optional) Create a symlink to use it from anywhere:
```bash
sudo ln -s $(pwd)/urltracker /usr/local/bin/urltracker
```

## Usage

### Basic URL Check

```bash
urltracker https://httpbin.org/status/200
```

### Process a List of URLs

Create a text file with one URL per line (e.g.: `urls.txt`):
```
https://httpbin.org/status/200
https://httpbin.org/redirect/2
https://httpbin.org/status/404
```

Then run:
```bash
urltracker --list urls.txt
```

### Output to CSV

```bash
urltracker --list urls.txt --output results.csv
```

### Using Authentication

```bash
urltracker --auth user:pass https://httpbin.org/basic-auth/user/pass
```

### Using Custom Headers

```bash
urltracker --header "User-Agent: Mozilla/5.0" --header "Accept-Language: en-US" https://httpbin.org/status/200
```

### Using Custom Method

```bash
urltracker --method PATCH https://httpbin.org/anything  --verbose
```

### Verbose Output

```bash
urltracker https://httpbin.org/redirect/2 --verbose
```

### Full Options List

```
Usage: urltracker [OPTIONS] [URL]

Options:
  -h, --help                   Display this help message
  -V, --version                Display the version
  -l, --list <file>            Process a list of URLs from a text file
  -o, --output <file>          Export results to a CSV file
  -v, --verbose                Verbose mode: show all redirect URLs
  -q, --quiet                  Quiet mode: no output to console
  -nc, --no-color              Disable colored output
  -m, --method <method> HTTP method to use (default: GET. HEAD is faster but some servers may block it)
  -a, --auth <user:password>   Use HTTP Basic Authentication
  -H, --header <header>        Add custom header (can be used multiple times)
  -c, --cookie <name=value>    Add a cookie (can be used multiple times)
```

## Development

### Running Tests

This project uses [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System) for testing. To run the tests:

1. Install BATS if you don't have it:
```bash
# MacOS
brew install bats-core

# Debian/Ubuntu
sudo apt-get install bats
```

2. Run the tests:
```bash
bats test_urltracker.bats
```

3. For verbose test output:
```bash
bats --tap test_urltracker.bats
```

4. For debug test output:
```bash
bats --print-output-on-failure --show-output-of-passing-tests test_urltracker.bats
```

### Test Coverage

The test suite covers:
- Basic functionality
- URL list processing
- Output formatting
- Error handling
- Authentication and custom headers
- Command-line option parsing

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and add tests for new functionality
4. Run the test suite to ensure everything passes (`bats test_urltracker.bats`)
5. Commit your changes (`git commit -am 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- The [BATS project](https://github.com/bats-core/bats-core) for the testing framework
- The command `curl -IL https://httpbin.org/redirect/2` that led me to create this project
- The amazing [httpx](https://github.com/projectdiscovery/httpx) as inspiration and a powerful alternative to this humble project
- The amazing [vhs](https://github.com/charmbracelet/vhs) CLI demo generator