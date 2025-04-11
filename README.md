# URL Tracker

A command-line tool to check HTTP status codes and track redirections for URLs.

## Overview

URL Tracker helps you analyze HTTP responses and redirects for single URLs or lists of URLs. Perfect for website maintenance, SEO auditing, and link checking.

Features:
- Single URL status checking
- Batch URL processing from a file
- Redirect chain tracking
- CSV output for further analysis
- Basic authentication support
- Custom headers and cookies

## Prerequisites

- Bash shell environment
- `curl` command-line tool
- `BATS` (Bash Automated Testing System) for running tests

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/urltracker.git
   cd urltracker
   ```

2. Make the script executable:
   ```bash
   chmod +x urltracker.sh
   ```

3. (Optional) Create a symlink to use it from anywhere:
   ```bash
   sudo ln -s $(pwd)/urltracker.sh /usr/local/bin/urltracker
   ```

## Usage

### Basic URL Check

```bash
./urltracker.sh https://httpbin.org/status/200
```

### Process a List of URLs

Create a text file with one URL per line:
```
https://httpbin.org/status/200
https://httpbin.org/redirect/2
https://httpbin.org/status/404
```

Then run:
```bash
./urltracker.sh --list urls.txt
```

### Output to CSV

```bash
./urltracker.sh --list urls.txt --output results.csv
```

### Using Authentication

```bash
./urltracker.sh --auth user:pass https://httpbin.org/basic-auth/user/pass
```

### Using Custom Headers

```bash
./urltracker.sh --header "User-Agent: Mozilla/5.0" --header "Accept-Language: en-US" https://httpbin.org/status/200
```

### Verbose Output

```bash
./urltracker.sh --verbose https://httpbin.org/redirect/2
```

### Full Options List

```
Usage: urltracker.sh [OPTIONS] [URL]

Options:
  --help, -h         Show this help message
  --verbose, -v      Enable verbose output
  --quiet, -q        Suppress all output
  --no-color         Disable colored output
  --list FILE        Process URLs from FILE (one URL per line)
  --output FILE      Save results to CSV FILE
  --auth USER:PASS   Use basic authentication
  --header HEADER    Add custom header (can be used multiple times)
  --cookie COOKIE    Add cookie (can be used multiple times)
```

## Development

### Running Tests

This project uses BATS (Bash Automated Testing System) for testing. To run the tests:

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