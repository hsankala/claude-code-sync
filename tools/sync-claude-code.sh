#!/usr/bin/env bash
# sync-claude-code.sh
# Assembles CLAUDE.md, web-ai-doc.md, and syncs Claude Code skills from claude-code-sync.yaml.
#
# Usage: ./sync-claude-code.sh [-Config <config-filename>]
#   -Config   Name of the config file to use (must be in the same directory as this script).
#             Defaults to claude-code-sync.yaml.
#
# Requires: bash 4+, curl, sha256sum (Linux) or shasum (macOS)

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
readonly SCRIPT_VERSION='0.1.2'

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
CONFIG_NAME='claude-code-sync.yaml'
while [[ $# -gt 0 ]]; do
    case "$1" in
        -Config|-config|--config)
            CONFIG_NAME="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Path setup — script lives in tools/ or scripts/, project root is one level up
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE_PATH="$SCRIPT_DIR/$CONFIG_NAME"
CLAUDE_MD_OUTPUT_PATH="$PROJECT_ROOT/CLAUDE.md"
WEB_AI_DOC_OUTPUT_PATH=''   # resolved after config is loaded
SKILLS_OUTPUT_DIR="$PROJECT_ROOT/.claude/commands"
DEFAULT_LOCAL_DOCS_DIR="$PROJECT_ROOT/ai-docs"

# ---------------------------------------------------------------------------
# Console output helpers — all write to stderr so functions can return values
# via stdout without interference
# ---------------------------------------------------------------------------
if [[ -t 2 ]]; then
    C_CYAN='\033[0;36m'
    C_WHITE='\033[1;37m'
    C_GREEN='\033[0;32m'
    C_DARK_GRAY='\033[0;90m'
    C_YELLOW='\033[0;33m'
    C_RED='\033[0;31m'
    C_RESET='\033[0m'
else
    C_CYAN=''; C_WHITE=''; C_GREEN=''; C_DARK_GRAY=''; C_YELLOW=''; C_RED=''; C_RESET=''
fi

write_section_header() { echo ""                                                  >&2; echo -e "${C_CYAN}=== $1 ===${C_RESET}"        >&2; }
write_step_info()       { echo -e "${C_WHITE}  -> $1${C_RESET}"                   >&2; }
write_step_success()    { echo -e "${C_GREEN}  [OK] $1${C_RESET}"                 >&2; }
write_step_skipped()    { echo -e "${C_DARK_GRAY}  [--] $1${C_RESET}"             >&2; }
write_step_warning()    { echo -e "${C_YELLOW}  [!!] $1${C_RESET}"                >&2; }
write_step_error()      { echo -e "${C_RED}  [XX] $1${C_RESET}"                   >&2; }

# Wrappers for the post-assembly summary lines (match PS1 colour pattern)
write_output_success()  { echo -e "${C_GREEN}  $1${C_RESET}"                      >&2; }
write_output_path()     { echo -e "${C_CYAN}  $1${C_RESET}"                       >&2; }
write_output_count()    { echo -e "${C_YELLOW}  $1${C_RESET}"                     >&2; }

# ---------------------------------------------------------------------------
# SHA-256 helper — works on Linux (sha256sum) and macOS (shasum -a 256)
# ---------------------------------------------------------------------------
compute_file_sha256() {
    local file_path="$1"
    if command -v sha256sum &>/dev/null; then
        sha256sum "$file_path" | cut -d' ' -f1
    elif command -v shasum &>/dev/null; then
        shasum -a 256 "$file_path" | cut -d' ' -f1
    else
        write_step_error "No SHA-256 utility found (sha256sum or shasum required)"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# YAML parsing — no external dependencies, handles our simple flat structure
# ---------------------------------------------------------------------------
get_yaml_scalar_value() {
    local key="$1"
    local file="$2"
    grep -m 1 "^${key}:" "$file" | sed "s/^${key}:[[:space:]]*//" | sed 's/[[:space:]]*$//' || true
}

# Prints one list item per line to stdout; caller captures with mapfile
get_yaml_list_section() {
    local section_name="$1"
    local file="$2"
    local inside_section=false

    while IFS= read -r line; do
        # key: []  — explicitly empty list
        if [[ "$line" =~ ^${section_name}:[[:space:]]*\[\] ]]; then
            return 0
        fi
        # Section header line
        if [[ "$line" =~ ^${section_name}: ]]; then
            inside_section=true
            continue
        fi
        if [[ "$inside_section" == true ]]; then
            # Any new top-level key ends this section
            if [[ "$line" =~ ^[a-zA-Z_] ]]; then
                return 0
            fi
            # List item — strip inline comments and trailing whitespace
            if [[ "$line" =~ ^[[:space:]]+-[[:space:]]+(.+) ]]; then
                local value="${BASH_REMATCH[1]}"
                value="${value%%#*}"                        # strip inline comment
                value="${value%"${value##*[![:space:]]}"}"  # strip trailing whitespace
                [[ -n "$value" ]] && echo "$value"
            fi
        fi
    done < "$file"
}

# ---------------------------------------------------------------------------
# Fetch a remote URL — fails loudly on any network or HTTP error
# Writes content to stdout
# ---------------------------------------------------------------------------
invoke_remote_fetch() {
    local url="$1"
    write_step_info "Fetching: $url"

    local tmp_file
    tmp_file=$(mktemp)

    local http_code
    http_code=$(curl -sS -L -w '%{http_code}' -o "$tmp_file" "$url" 2>&1) || {
        write_step_error "Network error fetching: $url"
        rm -f "$tmp_file"
        exit 1
    }

    if [[ "$http_code" != "200" ]]; then
        write_step_error "HTTP $http_code — $url"
        rm -f "$tmp_file"
        exit 1
    fi

    cat "$tmp_file"
    rm -f "$tmp_file"
}

# ---------------------------------------------------------------------------
# Read a single doc entry — remote URL, relative path, or ai-docs/ filename
# Writes content to stdout
# ---------------------------------------------------------------------------
read_doc_entry() {
    local entry="$1"
    local local_docs_dir="$2"

    if [[ "$entry" =~ ^https?:// ]]; then
        # Remote — fetch via HTTP
        invoke_remote_fetch "$entry"
    elif [[ "$entry" == */* ]]; then
        # Contains path separator — resolve relative to project root
        local full_path="$PROJECT_ROOT/$entry"
        if [[ ! -f "$full_path" ]]; then
            write_step_error "Local file not found: $full_path"
            exit 1
        fi
        write_step_info "Reading: $entry"
        cat "$full_path"
    else
        # Plain filename — look up in local docs directory
        local full_path="$local_docs_dir/$entry"
        if [[ ! -f "$full_path" ]]; then
            write_step_error "Local file not found: $full_path"
            write_step_error "Expected in: $local_docs_dir"
            exit 1
        fi
        write_step_info "Reading: $entry"
        cat "$full_path"
    fi
}

# ---------------------------------------------------------------------------
# Assemble a list of doc entries into a single output file
# Prints included count to stdout
# ---------------------------------------------------------------------------
invoke_doc_assembly() {
    local output_path="$1"
    local local_docs_dir="$2"
    shift 2
    local entries=("$@")

    local generated_header='<!-- Auto-generated by sync-claude-code. Do not edit manually. -->'
    local separator=$'\n\n---\n\n'
    local tmp_body_file
    tmp_body_file=$(mktemp)
    local included_count=0

    for entry in "${entries[@]}"; do
        local content
        content=$(read_doc_entry "$entry" "$local_docs_dir")

        if [[ $included_count -gt 0 ]]; then
            printf '%s' "$separator" >> "$tmp_body_file"
        fi
        printf '%s' "$content" >> "$tmp_body_file"

        write_step_success "Included: $entry"
        (( included_count++ )) || true
    done

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    {
        printf '%s\n\n' "$generated_header"
        cat "$tmp_body_file"
        printf '\n\n\n---\n\n## Sync Summary\n\n'
        printf '**Generated:** %s\n' "$timestamp"
        printf '**Output:** %s\n' "$output_path"
        printf '**Documents included (%d):**\n' "$included_count"
        for entry in "${entries[@]}"; do
            printf -- '- %s\n' "$entry"
        done
    } > "$output_path"

    rm -f "$tmp_body_file"

    echo "$included_count"
}

# ---------------------------------------------------------------------------
# Sync skills to .claude/commands/
# Prints synced count to stdout
# ---------------------------------------------------------------------------
invoke_skills_sync() {
    local local_docs_dir="$1"
    shift
    local entries=("$@")

    if [[ ! -d "$SKILLS_OUTPUT_DIR" ]]; then
        mkdir -p "$SKILLS_OUTPUT_DIR"
        write_step_info "Created: $SKILLS_OUTPUT_DIR"
    fi

    local synced_count=0

    for entry in "${entries[@]}"; do
        local content
        content=$(read_doc_entry "$entry" "$local_docs_dir")
        local filename
        filename=$(basename "$entry")
        local dest_path="$SKILLS_OUTPUT_DIR/$filename"
        printf '%s' "$content" > "$dest_path"
        write_step_success "Synced skill: $filename -> $dest_path"
        (( synced_count++ )) || true
    done

    echo "$synced_count"
}

# ===========================================================================
# MAIN
# ===========================================================================

echo "" >&2
echo -e "${C_CYAN}Claude Code Sync  v${SCRIPT_VERSION}${C_RESET}" >&2
echo -e "${C_DARK_GRAY}Project root: $PROJECT_ROOT${C_RESET}"      >&2
echo -e "${C_DARK_GRAY}Config:       $CONFIG_FILE_PATH${C_RESET}"  >&2

# ---------------------------------------------------------------------------
# Load config
# ---------------------------------------------------------------------------
write_section_header "Loading Config"

if [[ ! -f "$CONFIG_FILE_PATH" ]]; then
    write_step_error "Config file not found: $CONFIG_FILE_PATH"
    write_step_error "Expected claude-code-sync.yaml alongside this script in $SCRIPT_DIR"
    exit 1
fi

write_step_success "Config loaded: $CONFIG_FILE_PATH"

GITHUB_BASE_URL=$(get_yaml_scalar_value 'github_base_url' "$CONFIG_FILE_PATH")
SCRIPT_REMOTE_PATH=$(get_yaml_scalar_value 'script_path_sh' "$CONFIG_FILE_PATH")
if [[ -z "$SCRIPT_REMOTE_PATH" ]]; then
    SCRIPT_REMOTE_PATH=$(get_yaml_scalar_value 'script_path' "$CONFIG_FILE_PATH")
fi

if [[ -n "$GITHUB_BASE_URL" && -n "$SCRIPT_REMOTE_PATH" ]]; then
    REMOTE_SCRIPT_URL="$GITHUB_BASE_URL/$SCRIPT_REMOTE_PATH"
else
    REMOTE_SCRIPT_URL=''
fi

LOCAL_DOCS_DIR_OVERRIDE=$(get_yaml_scalar_value 'local_docs_dir' "$CONFIG_FILE_PATH")
if [[ -n "$LOCAL_DOCS_DIR_OVERRIDE" ]]; then
    LOCAL_DOCS_DIR="$PROJECT_ROOT/$LOCAL_DOCS_DIR_OVERRIDE"
else
    LOCAL_DOCS_DIR="$DEFAULT_LOCAL_DOCS_DIR"
fi

WEB_AI_DOC_FILENAME=$(get_yaml_scalar_value 'web_ai_doc_filename' "$CONFIG_FILE_PATH")
if [[ -z "$WEB_AI_DOC_FILENAME" ]]; then
    WEB_AI_DOC_FILENAME='web-ai-doc.md'
fi
WEB_AI_DOC_OUTPUT_PATH="$PROJECT_ROOT/$WEB_AI_DOC_FILENAME"

mapfile -t CLAUDE_MD_ENTRIES < <(get_yaml_list_section 'claude_md' "$CONFIG_FILE_PATH")
mapfile -t WEB_AI_DOC_ENTRIES < <(get_yaml_list_section 'web_ai_doc' "$CONFIG_FILE_PATH")
mapfile -t SKILLS_ENTRIES     < <(get_yaml_list_section 'skills'     "$CONFIG_FILE_PATH")

write_step_info "claude_md entries:  ${#CLAUDE_MD_ENTRIES[@]}"
write_step_info "web_ai_doc entries: ${#WEB_AI_DOC_ENTRIES[@]}"
write_step_info "skills entries:     ${#SKILLS_ENTRIES[@]}"
write_step_info "Local docs dir:     $LOCAL_DOCS_DIR"
[[ -n "$GITHUB_BASE_URL" ]] && write_step_info "GitHub base URL:    $GITHUB_BASE_URL"

# ---------------------------------------------------------------------------
# Self-update — fetch remote script, compare hashes, overwrite if changed
# ---------------------------------------------------------------------------
write_section_header "Checking for Script Updates"

if [[ -z "$REMOTE_SCRIPT_URL" ]]; then
    write_step_skipped "No github_base_url/script_path in config — skipping self-update"
else
    write_step_info "Remote: $REMOTE_SCRIPT_URL"

    local_hash=$(compute_file_sha256 "${BASH_SOURCE[0]}")

    tmp_remote_script=$(mktemp)
    write_step_info "Fetching: $REMOTE_SCRIPT_URL"
    remote_http_code=$(curl -sS -L -w '%{http_code}' -o "$tmp_remote_script" "$REMOTE_SCRIPT_URL" 2>&1) || {
        write_step_error "Network error fetching: $REMOTE_SCRIPT_URL"
        rm -f "$tmp_remote_script"
        exit 1
    }
    if [[ "$remote_http_code" != "200" ]]; then
        write_step_error "HTTP $remote_http_code — $REMOTE_SCRIPT_URL"
        rm -f "$tmp_remote_script"
        exit 1
    fi

    remote_hash=$(compute_file_sha256 "$tmp_remote_script")

    if [[ "$local_hash" == "$remote_hash" ]]; then
        write_step_success "Script is up to date"
        rm -f "$tmp_remote_script"
    else
        write_step_info "Update found — overwriting script"
        cp "$tmp_remote_script" "${BASH_SOURCE[0]}"
        chmod +x "${BASH_SOURCE[0]}"
        rm -f "$tmp_remote_script"
        write_step_success "Script updated successfully"
        echo ""                                                                                                    >&2
        echo -e "${C_YELLOW}  Script has been updated. Please rerun to continue with the latest version.${C_RESET}" >&2
        echo ""                                                                                                    >&2
        exit 0
    fi
fi

# ---------------------------------------------------------------------------
# Assemble CLAUDE.md
# ---------------------------------------------------------------------------
write_section_header "Assembling CLAUDE.md"

if [[ ${#CLAUDE_MD_ENTRIES[@]} -gt 0 ]]; then
    claude_md_included_count=$(invoke_doc_assembly "$CLAUDE_MD_OUTPUT_PATH" "$LOCAL_DOCS_DIR" "${CLAUDE_MD_ENTRIES[@]}")
    echo "" >&2
    write_output_success "CLAUDE.md written successfully"
    write_output_path    "Output:   $CLAUDE_MD_OUTPUT_PATH"
    write_output_count   "Included: ${claude_md_included_count} document(s)"
else
    write_step_skipped "No claude_md entries in config — skipping"
fi

# ---------------------------------------------------------------------------
# Assemble Web AI Documentation
# ---------------------------------------------------------------------------
write_section_header "Assembling Web AI Documentation"

if [[ ${#WEB_AI_DOC_ENTRIES[@]} -gt 0 ]]; then
    web_ai_doc_included_count=$(invoke_doc_assembly "$WEB_AI_DOC_OUTPUT_PATH" "$LOCAL_DOCS_DIR" "${WEB_AI_DOC_ENTRIES[@]}")
    echo "" >&2
    write_output_success "$WEB_AI_DOC_FILENAME written successfully"
    write_output_path    "Output:   $WEB_AI_DOC_OUTPUT_PATH"
    write_output_count   "Included: ${web_ai_doc_included_count} document(s)"
else
    write_step_skipped "No web_ai_doc entries in config — skipping"
fi

# ---------------------------------------------------------------------------
# Sync skills
# ---------------------------------------------------------------------------
write_section_header "Syncing Skills"

if [[ ${#SKILLS_ENTRIES[@]} -gt 0 ]]; then
    skills_synced_count=$(invoke_skills_sync "$LOCAL_DOCS_DIR" "${SKILLS_ENTRIES[@]}")
    echo "" >&2
    write_output_success "Skills synced successfully"
    write_output_path    "Output:  $SKILLS_OUTPUT_DIR"
    write_output_count   "Synced:  ${skills_synced_count} skill(s)"
else
    write_step_skipped "No skills entries in config — skipping"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""                                                              >&2
echo -e "${C_DARK_GRAY}================================${C_RESET}"  >&2
echo -e "${C_GREEN}  Sync complete.${C_RESET}"                      >&2
echo -e "${C_DARK_GRAY}================================${C_RESET}"  >&2
echo ""                                                              >&2
