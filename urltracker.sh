#!/bin/bash

# Colors
RESET="\033[0m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"

# Function to get color for a status code - compatible with older Bash
get_status_color() {
    local status=$1
    
    # Check if specific status code has specific color (using case instead of associative array)
    case "$status" in
        # Success codes - green
        200|201|202|203|204|205|206)
            echo "$GREEN"
            ;;
        # Redirect codes - yellow
        300|301|302|303|304|307|308)
            echo "$YELLOW"
            ;;
        # Client error codes - red
        400|401|403|404|405|429)
            echo "$RED"
            ;;
        # Server error codes - red
        500|501|502|503|504)
            echo "$RED"
            ;;
        # Default coloring by status category
        *)
            # Extract first digit of status code
            local first_digit="${status:0:1}"
            case "$first_digit" in
                2) echo "$GREEN" ;;
                3) echo "$YELLOW" ;;
                4|5) echo "$RED" ;;
                *) echo "$RESET" ;;
            esac
            ;;
    esac
}

# Help function
show_help() {
    echo "Usage: $0 [options] [URL]"
    echo ""
    echo "Options:"
    echo "  -h, --help           Display this help message"
    echo "  -l, --list <file>    Process a list of URLs from a text file"
    echo "  -o, --output <file>  Export results to a CSV file"
    echo "  -v, --verbose        Verbose mode: show all redirect URLs"
    echo "  -q, --quiet          Quiet mode: no output to console"
    echo "  -nc, --no-color      Disable colored output"
    echo "  -a, --auth <user:password>   Use HTTP Basic Authentication"
    echo "  -H, --header <header>        Add custom header (can be used multiple times)"
    echo "  -c, --cookie <name=value>    Add a cookie (can be used multiple times)"
    echo ""
    echo "Examples:"
    echo "  $0 https://example.com"
    echo "  $0 --list urls.txt"
    echo "  $0 --list urls.txt --output results.csv"
    echo "  $0 --verbose https://example.com"
    echo "  $0 --auth username:password https://example.com"
    echo "  $0 --header \"User-Agent: Mozilla/5.0\" https://example.com"
    echo "  $0 --cookie \"session=abc123\" https://example.com"
    echo "  $0 --quiet --list urls.txt --output results.csv"
    echo ""
    echo "The script displays information in the format:"
    echo "  <ORIGINAL_URL> [STATUS_CODES_LIST] <FINAL_URL>"
    echo ""
    echo "When exporting to CSV, the following columns are included:"
    echo "  Origin,StatusCode,EffectiveUrl"
    echo ""
    echo "Color coding:"
    echo -e "  ${GREEN}Green${RESET}:  Success status codes (2xx)"
    echo -e "  ${YELLOW}Yellow${RESET}: Redirect status codes (3xx)"
    echo -e "  ${RED}Red${RESET}:    Error status codes (4xx, 5xx)"
    echo -e "  ${BLUE}Blue${RESET}:   Final destination URL"
    exit 0
}

# Function to build curl command safely
build_curl_command() {
    local base_cmd="$1"
    local url="$2"
    
    # Start with base curl options
    local cmd="curl $base_cmd"
    
    # Add authentication if provided
    if [ -n "$AUTH" ]; then
        cmd="$cmd -u '$AUTH'"
    fi
    
    # Add headers if provided
    for header in "${HEADERS[@]}"; do
        cmd="$cmd -H '$header'"
    done
    
    # Add cookies if provided
    for cookie in "${COOKIES[@]}"; do
        cmd="$cmd -b '$cookie'"
    done
    
    # Add URL (quoted to handle special characters)
    cmd="$cmd '$url'"
    
    echo "$cmd"
}

# Function to process a single URL
process_url() {
    local URL="$1"
    local CSV_FILE="$2"
    local VERBOSITY="$3"
    local USE_COLOR="$4"
    
    # Build base curl command
    local BASE_CURL_OPTS="-sIL -w '%{url_effective}\n%{http_code}\n' -o /dev/null"
    local CURL_CMD=$(build_curl_command "$BASE_CURL_OPTS" "$URL")
    
    # Execute command and capture output
    output=$(eval "$CURL_CMD")
    effective_url=$(echo "$output" | head -1)
    final_status=$(echo "$output" | tail -1)

    # For verbose mode, we need to capture all intermediate URLs and status codes
    if [ "$VERBOSITY" = "verbose" ]; then
        # Create a temporary file for headers
        temp_file=$(mktemp)
        
        # Use curl with -D to dump headers to file
        local HEADER_CURL_OPTS="-sIL -o /dev/null -D $temp_file"
        local HEADER_CURL_CMD=$(build_curl_command "$HEADER_CURL_OPTS" "$URL")
        eval "$HEADER_CURL_CMD"
        
        # Process the headers more carefully to associate each status code with the right URL
        STATUS_CODES=()
        REDIRECT_URLS=()
        REDIRECT_URLS[0]="$URL"  # Start with the original URL
        
        current_status=""
        redirect_count=0
        
        while IFS= read -r line || [ -n "$line" ]; do
            # If line starts with HTTP, it's a status line
            if [[ "$line" =~ ^HTTP/ ]]; then
                current_status=$(echo "$line" | awk '{print $2}')
                STATUS_CODES[$redirect_count]="$current_status"
            # If line starts with Location, it's a redirect
            elif [[ "$line" =~ ^[Ll]ocation:\ (.*) ]]; then
                location="${BASH_REMATCH[1]}"
                # Remove carriage return if present
                location=$(echo "$location" | tr -d '\r')
                redirect_count=$((redirect_count + 1))
                REDIRECT_URLS[$redirect_count]="$location"
            fi
        done < "$temp_file"
        
        # Make sure we have the final status code
        # For non-redirect responses, we might only have one status code
        if [ ${#STATUS_CODES[@]} -le $redirect_count ]; then
            # Make one more request to get the final status code
            local STATUS_CURL_OPTS="-sI -o /dev/null -w '%{http_code}'"
            local STATUS_CURL_CMD=$(build_curl_command "$STATUS_CURL_OPTS" "$effective_url")
            final_code=$(eval "$STATUS_CURL_CMD")
            STATUS_CODES[$redirect_count]="$final_code"
        fi
        
        rm "$temp_file"
    else
        # For normal mode, we just need the status codes
        local STATUS_CURL_OPTS="-sIL"
        local STATUS_CURL_CMD=$(build_curl_command "$STATUS_CURL_OPTS" "$URL")
        status_output=$(eval "$STATUS_CURL_CMD" | grep -i "HTTP/" | awk '{print $2}')
        
        # Convert status codes to array
        STATUS_CODES=()
        i=0
        while read -r status; do
            STATUS_CODES[$i]="$status"
            i=$((i + 1))
        done <<< "$status_output"
    fi

    # Format status string with semicolons for both display and CSV
    status_string="["
    status_csv=""
    
    # Apply colors to status codes if enabled
    for i in $(seq 0 $((${#STATUS_CODES[@]} - 1))); do
        status_code="${STATUS_CODES[$i]}"
        status_csv+="${status_code}"
        
        # Add color to status code if colors are enabled
        if [ "$USE_COLOR" = "true" ]; then
            status_color=$(get_status_color "$status_code")
            status_string+="${status_color}${status_code}${RESET}"
        else
            status_string+="${status_code}"
        fi
        
        if [ $i -lt $(( ${#STATUS_CODES[@]} - 1 )) ]; then
            status_string+=";"
            status_csv+=";"
        fi
    done
    status_string+="]"

    # Display result based on verbosity
    if [ "$VERBOSITY" = "normal" ]; then
        if [ "$USE_COLOR" = "true" ]; then
            echo -e "$URL $status_string ${BLUE}$effective_url${RESET}"
        else
            echo "$URL $status_string $effective_url"
        fi
    elif [ "$VERBOSITY" = "verbose" ]; then
        echo -e "Original URL: $URL"
        echo -e "Status codes: $status_string"
        echo "Redirect chain:"
        
        # Display URLs with their corresponding status codes
        for i in $(seq 0 $((${#REDIRECT_URLS[@]} - 1))); do
            status_code="${STATUS_CODES[$i]}"
            url="${REDIRECT_URLS[$i]}"
            
            # For the last item, use the effective URL instead of the path 
            # if the last URL is just a path
            if [ $i -eq $(( ${#REDIRECT_URLS[@]} - 1 )) ]; then
                # If last URL is just a path, use effective URL
                if [[ "$url" == /* ]]; then
                    url="$effective_url"
                fi
            fi
            
            if [ "$USE_COLOR" = "true" ]; then
                status_color=$(get_status_color "$status_code")
                
                # Apply blue color to final URL
                if [ $i -eq $(( ${#REDIRECT_URLS[@]} - 1 )) ]; then
                    echo -e "  [${status_color}${status_code}${RESET}] ${BLUE}${url}${RESET}"
                else
                    echo -e "  [${status_color}${status_code}${RESET}] ${url}"
                fi
            else
                echo "  [${status_code}] ${url}"
            fi
        done
        echo "-------------------------------------"
    fi
    
    # Export to CSV if requested
    if [ -n "$CSV_FILE" ]; then
        echo "\"$URL\",\"$status_csv\",\"$effective_url\"" >> "$CSV_FILE"
    fi
}

# Check if no arguments
if [ $# -eq 0 ]; then
    show_help
fi

# Initialize variables
LIST_FILE=""
CSV_FILE=""
SINGLE_URL=""
VERBOSITY="normal"  # Default verbosity
USE_COLOR="true"    # Default to using colors
AUTH=""             # Authentication credentials
HEADERS=()          # Array for custom headers
COOKIES=()          # Array for cookies

# Detect if we're on macOS
IS_MACOS=false
if [ "$(uname)" == "Darwin" ]; then
    IS_MACOS=true
fi

# Process arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        -l|--list)
            if [ -z "$2" ] || [ ! -f "$2" ]; then
                echo "Error: List file not specified or not found."
                echo "Use '$0 --help' for more information."
                exit 1
            fi
            LIST_FILE="$2"
            shift 2
            ;;
        -o|--output)
            if [ -z "$2" ]; then
                echo "Error: Output file not specified."
                echo "Use '$0 --help' for more information."
                exit 1
            fi
            CSV_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSITY="verbose"
            shift
            ;;
        -q|--quiet)
            VERBOSITY="quiet"
            shift
            ;;
        -nc|--no-color)
            USE_COLOR="false"
            shift
            ;;
        -a|--auth)
            if [ -z "$2" ]; then
                echo "Error: Authentication credentials not specified."
                echo "Use '$0 --help' for more information."
                exit 1
            fi
            AUTH="$2"
            shift 2
            ;;
        -H|--header)
            if [ -z "$2" ]; then
                echo "Error: Header not specified."
                echo "Use '$0 --help' for more information."
                exit 1
            fi
            HEADERS+=("$2")
            shift 2
            ;;
        -c|--cookie)
            if [ -z "$2" ]; then
                echo "Error: Cookie not specified."
                echo "Use '$0 --help' for more information."
                exit 1
            fi
            COOKIES+=("$2")
            shift 2
            ;;
        # Mantendo compatibilidade com as opções antigas
        -list)
            if [ -z "$2" ] || [ ! -f "$2" ]; then
                echo "Error: List file not specified or not found."
                echo "Use '$0 --help' for more information."
                exit 1
            fi
            LIST_FILE="$2"
            shift 2
            ;;
        -output)
            if [ -z "$2" ]; then
                echo "Error: Output file not specified."
                echo "Use '$0 --help' for more information."
                exit 1
            fi
            CSV_FILE="$2"
            shift 2
            ;;
        *)
            SINGLE_URL="$1"
            shift
            ;;
    esac
done

# Create CSV header if exporting to CSV
if [ -n "$CSV_FILE" ]; then
    echo "Origin,StatusCode,EffectiveUrl" > "$CSV_FILE"
fi

# Process URLs
if [ -n "$LIST_FILE" ]; then
    # Process each URL from the file
    while IFS= read -r url || [ -n "$url" ]; do
        # Skip empty lines and comments
        if [ -n "$url" ] && [[ ! "$url" =~ ^[[:space:]]*# ]]; then
            if [ "$VERBOSITY" != "quiet" ]; then
                process_url "$url" "$CSV_FILE" "$VERBOSITY" "$USE_COLOR"
            else
                process_url "$url" "$CSV_FILE" "$VERBOSITY" "false" > /dev/null
            fi
        fi
    done < "$LIST_FILE"
elif [ -n "$SINGLE_URL" ]; then
    # Process a single URL
    if [ "$VERBOSITY" != "quiet" ]; then
        process_url "$SINGLE_URL" "$CSV_FILE" "$VERBOSITY" "$USE_COLOR"
    else
        process_url "$SINGLE_URL" "$CSV_FILE" "$VERBOSITY" "false" > /dev/null
    fi
else
    show_help
fi