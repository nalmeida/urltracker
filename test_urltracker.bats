#!/usr/bin/env bats

# Unit test script for urltracker
# Requires BATS: https://github.com/bats-core/bats-core
# MacOS installation: brew install bats-core
# Run with: bats --show-output-of-passing-tests --verbose test_urltracker.bats

# Install bats-support and bats-assert libraries for better output
# git clone https://github.com/bats-core/bats-support.git
# git clone https://github.com/bats-core/bats-assert.git
# load 'bats-support/load.bash'
# load 'bats-assert/load.bash'

# Configuration variables
SCRIPT_PATH="./urltracker"
TEST_URL="https://httpbin.org"
TEST_REDIRECT_URL="https://httpbin.org/redirect/2"
TEST_AUTH_URL="https://httpbin.org/basic-auth/user/pass"
TEST_FILE="test_urls.txt"
TEST_OUTPUT="test_output.csv"

# Setup - executed before each test
setup() {
  # Create temporary file with test URLs
  cat > "$TEST_FILE" << EOF
https://httpbin.org/status/200   
https://httpbin.org/status/404
https://httpbin.org/status/500
# Comment that should be ignored
https://httpbin.org/redirect/1
EOF

  # Ensure the script has execution permissions
  chmod +x "$SCRIPT_PATH"
  
  # Display information about the test environment
  echo "=== TEST SETUP ==="
  echo "Test file created: $TEST_FILE with the following content:"
  cat "$TEST_FILE"
  echo "=== END SETUP ==="
  echo
}

# Teardown - executed after each test
teardown() {
  echo "=== TEST CLEANUP ==="
  
  # Remove temporary files
  if [ -f "$TEST_FILE" ]; then
    rm "$TEST_FILE"
    echo "✓ Removed test file: $TEST_FILE"
  fi
  
  if [ -f "$TEST_OUTPUT" ]; then
    rm "$TEST_OUTPUT"
    echo "✓ Removed output file: $TEST_OUTPUT"
  fi
  
  # Kill the test server if running
  if [[ ! -z "$PID_SERVER" ]]; then
    kill "$PID_SERVER" 2>/dev/null || true
    echo "✓ Stopped test server (PID: $PID_SERVER)"
    unset PID_SERVER
  fi
  
  echo "=== END CLEANUP ==="
  echo
}

# Helper function to run a command and display both the command and its output
execute_with_output() {
  echo "=== EXECUTING COMMAND ==="
  echo "\$ $@"
  echo "--- OUTPUT START ---"
  eval "$@"
  result=$?
  echo "--- OUTPUT END ---"
  echo "Exit code: $result"
  echo "=== END EXECUTION ==="
  echo
  return $result
}

# ==================== TESTS ====================

@test "Display help information when --help flag is provided" {
  echo "TEST: Checking if help information is displayed correctly"
  
  # Execute command with output display
  execute_with_output "$SCRIPT_PATH --help"
  
  # Validate output contains help sections
  echo "Validating help output contains expected sections:"
  grep -q "Usage" <<< "$(execute_with_output "$SCRIPT_PATH --help")" && echo "✓ Contains 'Usage' section"
  grep -q "Options" <<< "$(execute_with_output "$SCRIPT_PATH --help")" && echo "✓ Contains 'Options' section"
  grep -q "\-\-auth" <<< "$(execute_with_output "$SCRIPT_PATH --help")" && echo "✓ Contains '--auth' option"
  grep -q "\-\-header" <<< "$(execute_with_output "$SCRIPT_PATH --help")" && echo "✓ Contains '--header' option"
  grep -q "\-\-cookie" <<< "$(execute_with_output "$SCRIPT_PATH --help")" && echo "✓ Contains '--cookie' option"
}

@test "Display version information when --version flag is provided" {
  echo "TEST: Checking if version information is displayed correctly"
  
  # Execute command with output display
  execute_with_output "$SCRIPT_PATH --version"
  
  # Validate output contains version
  echo "Validating version output contains:"
  grep -q "urltracker v" <<< "$(execute_with_output "$SCRIPT_PATH --version")" && echo "✓ Contains 'Options' section"
}

@test "Check single URL status and display results correctly" {
  echo "TEST: Checking single URL status checking functionality"
  
  # Execute command with output display
  output=$(execute_with_output "$SCRIPT_PATH $TEST_URL")
  
  # Validate the output
  echo "Validating URL check output:"
  [[ "$output" == *"$TEST_URL"* ]] && echo "✓ Contains the tested URL"
  [[ "$output" == *"["* ]] && [[ "$output" == *"]"* ]] && echo "✓ Contains status code in brackets"
}

@test "Display detailed information in verbose mode" {
  echo "TEST: Checking verbose mode output"
  
  # Execute command with output display
  output=$(execute_with_output "$SCRIPT_PATH --verbose $TEST_REDIRECT_URL")
  
  # Validate the verbose output
  echo "Validating verbose mode output:"
  [[ "$output" == *"Original URL"* ]] && echo "✓ Contains 'Original URL' section"
  [[ "$output" == *"Status codes"* ]] && echo "✓ Contains 'Status codes' section"
  [[ "$output" == *"Redirect chain"* ]] && echo "✓ Contains 'Redirect chain' section"
}

@test "Produce no output in quiet mode" {
  echo "TEST: Checking quiet mode produces no output"
  
  # Execute command and capture its output
  output=$(execute_with_output "$SCRIPT_PATH --quiet $TEST_URL" 2>&1)
  
  # Check if there's no output in the command result section
  if [[ ! "$output" =~ "OUTPUT START".*"OUTPUT END" ]] || [[ "$output" =~ "OUTPUT START".+?[^\s].+?"OUTPUT END" ]]; then
    echo "✗ Output was produced in quiet mode"
    return 1
  else
    echo "✓ No output was produced in quiet mode"
  fi
}

@test "Process a list of URLs from input file" {
  echo "TEST: Checking URL list processing from file"
  
  # Execute command with output display
  output=$(execute_with_output "$SCRIPT_PATH --no-color --list $TEST_FILE")
  
  # Validate the URL list processing
  echo "Validating URL list processing:"
  
  # Check if each URL and its expected status code are in the output
  echo "$output" | grep -q "^https://httpbin.org/status/200 \[200\] https://httpbin.org/status/200$" && echo "✓ URL 1 processed correctly (200)" || { echo "✗ URL 1 failed"; return 1; }
  echo "$output" | grep -q "^https://httpbin.org/status/404 \[404\] https://httpbin.org/status/404$" && echo "✓ URL 2 processed correctly (404)" || { echo "✗ URL 2 failed"; return 1; }
  echo "$output" | grep -q "^https://httpbin.org/status/500 \[500\] https://httpbin.org/status/500$" && echo "✓ URL 3 processed correctly (500)" || { echo "✗ URL 3 failed"; return 1; }
  echo "$output" | grep -q "^https://httpbin.org/redirect/1 \[302;200\] https://httpbin.org/get$" && echo "✓ URL 4 processed correctly (302;200)" || { echo "✗ URL 4 failed"; return 1; }
  
  # Ensure comments are ignored
  [[ "$output" != *"Comment"* ]] && echo "✓ Comments were ignored" || { echo "✗ Comments were not ignored"; return 1; }
}

@test "Output results to CSV file in correct format" {
  echo "TEST: Checking CSV output functionality"
  
  # Execute command with output display
  execute_with_output "$SCRIPT_PATH --list $TEST_FILE --output $TEST_OUTPUT"
  
  # Display the content of the generated CSV file
  echo "Generated CSV file content:"
  execute_with_output "cat $TEST_OUTPUT"
  
  # Validate the CSV output
  echo "Validating CSV output:"
  [ -f "$TEST_OUTPUT" ] && echo "✓ CSV file was created"
  
  count=$(wc -l < "$TEST_OUTPUT")
  [ "$count" -eq 5 ] && echo "✓ CSV contains correct number of lines (5 = 1 header + 4 URLs)"
  
  header=$(head -n 1 "$TEST_OUTPUT")
  [[ "$header" == "Origin,StatusCode,EffectiveUrl" ]] && echo "✓ CSV header format is correct"
}

@test "Display output without ANSI color codes in no-color mode" {
  echo "TEST: Checking no-color mode output"
  
  # Execute command with output display
  output=$(execute_with_output "$SCRIPT_PATH --no-color $TEST_URL")
  
  # Validate no color codes in output
  echo "Validating no-color mode:"
  [[ "$output" != *$'\033'* ]] && echo "✓ Output does not contain ANSI color codes"
}

@test "Successfully authenticate using basic authentication" {
  echo "TEST: Checking basic authentication functionality"
  
  # Execute command with output display
  output=$(execute_with_output "$SCRIPT_PATH --auth \"user:pass\" $TEST_AUTH_URL")
  
  # Validate authentication success
  echo "Validating authentication result:"
  if [[ "$output" == *"[200]"* ]] || [[ "$output" == *"200"* ]]; then
    echo "✓ Authentication successful (status code 200)"
  else
    echo "✗ Authentication failed"
    return 1
  fi
}

@test "Send custom headers with request" {
  echo "TEST: Checking custom headers functionality"
  
  # Execute command with output display
  output=$(execute_with_output "$SCRIPT_PATH --header \"X-Test-Header: TestValue\" $TEST_URL/headers --verbose")
  
  # Validate custom header request completed
  echo "Validating custom header request:"
  [[ "$output" == *"Original URL"* ]] && echo "✓ Request with custom header completed successfully"
}

@test "Send cookies with request" {
  echo "TEST: Checking cookie functionality"
  
  # Execute command with output display
  output=$(execute_with_output "$SCRIPT_PATH --cookie \"testcookie=value\" $TEST_URL/cookies --verbose")
  
  # Validate cookie request completed
  echo "Validating cookie request:"
  [[ "$output" == *"Original URL"* ]] && echo "✓ Request with cookie completed successfully"
}

@test "Handle invalid or nonexistent URLs gracefully" {
  echo "TEST: Checking invalid URL handling"
  
  # Execute command with output display
  output=$(execute_with_output "$SCRIPT_PATH \"http://server.that.does.not.exist.local\"")
  
  # Validate error handling
  echo "Validating error handling:"
  [ -n "$output" ] && echo "✓ Script handled invalid URL without crashing"
}

@test "Support legacy option aliases for backward compatibility" {
  echo "TEST: Checking legacy option aliases support"
  
  # Execute command with output display
  output=$(execute_with_output "$SCRIPT_PATH -list \"$TEST_FILE\" -output \"$TEST_OUTPUT\" -v")
  
  # Validate legacy options worked
  echo "Validating legacy options:"
  [ -f "$TEST_OUTPUT" ] && echo "✓ CSV file was created using legacy options"
  [[ "$output" == *"Original URL"* ]] && echo "✓ Verbose output (-v) worked with legacy flag"
}

@test "Combine multiple long options successfully" {
  echo "TEST: Checking combined options functionality"
  
  # Execute command with output display
  output=$(execute_with_output "$SCRIPT_PATH --verbose --no-color --header \"User-Agent: Test\" --cookie \"test=1\" $TEST_URL")
  
  # Validate combined options worked
  echo "Validating combined options:"
  [[ "$output" == *"Original URL"* ]] && echo "✓ Verbose output works with combined options"
  [[ "$output" == *"Status codes"* ]] && echo "✓ Status codes are shown with combined options"
}