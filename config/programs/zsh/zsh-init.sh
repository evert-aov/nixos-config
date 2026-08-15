setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

cd() {
  builtin cd $@ &&
  ls
}

qcopy() {
    # 1. Dependency Checks
    if ! command -v wl-copy &> /dev/null; then
        echo "Error: 'wl-copy' is not installed. Please install wl-clipboard."
        return 1
    fi

    if ! command -v fzf &> /dev/null; then
        echo "Error: 'fzf' is not installed. Please install fzf."
        return 1
    fi

    # Determine the best preview tool (use 'bat' if installed for syntax highlighting, otherwise 'cat')
    local PREVIEW_CMD="cat {}"
    if command -v bat &> /dev/null; then
        PREVIEW_CMD="bat --style=numbers --color=always {}"
    elif command -v batcat &> /dev/null; then
        PREVIEW_CMD="batcat --style=numbers --color=always {}"
    fi

    # 2. Run the TUI (fzf)
    # --multi: Allows selecting multiple files with TAB
    # --layout=reverse: Puts the prompt at the top
    local selected_files
    selected_files=$(find . -type f -not -path "*/\.git/*" 2>/dev/null | fzf --multi \
        --layout=reverse \
        --preview="$PREVIEW_CMD" \
        --preview-window=right:60%:wrap \
        --prompt="Select files > " \
        --header="Use ARROW KEYS to navigate. Press TAB to select files, ENTER to copy to clipboard, ESC to cancel.")

    # 3. Handle Exit/Cancel
    if [[ -z "$selected_files" ]]; then
        echo "No files selected. Exited qcopy."
        return 0
    fi

    # 4. Process and Format Selected Files
    local temp_file
    temp_file=$(mktemp)

    # Read the fzf output line by line safely (handles spaces in filenames)
    while IFS= read -r file; do
        # Remove the leading './' from the find output for cleaner paths
        local clean_file="${file#./}"

        # Format exactly as requested: File name followed by contents
        echo "file name: $clean_file" >> "$temp_file"
        echo "file contents:" >> "$temp_file"
        cat "$file" >> "$temp_file"
        echo -e "\n----------------------------------------\n" >> "$temp_file"
    done <<< "$selected_files"

    # 5. Copy to Clipboard
    cat "$temp_file" | wl-copy

    # 6. Success Output
    local file_count=$(echo "$selected_files" | wc -l)
    echo "Success! Copied $file_count file(s) to your Wayland clipboard. Ready to paste to your LLM."

    # 7. Cleanup
    rm -f "$temp_file"
}

function fetch() {
    local color_file="/tmp/qs_colors.json"
    local config_path="/tmp/qs_fastfetch.jsonc"
    
    # Extract analogous cool tones
    local c_blue=$(grep -E '"blue"\s*:\s*"[^"]+"' "$color_file" 2>/dev/null | cut -d '"' -f 4)
    c_blue=${c_blue:-"#89b4fa"}
    
    local c_sapphire=$(grep -E '"sapphire"\s*:\s*"[^"]+"' "$color_file" 2>/dev/null | cut -d '"' -f 4)
    c_sapphire=${c_sapphire:-"#74c7ec"}
    
    local c_teal=$(grep -E '"teal"\s*:\s*"[^"]+"' "$color_file" 2>/dev/null | cut -d '"' -f 4)
    c_teal=${c_teal:-"#94e2d5"}
    
    local c_mauve=$(grep -E '"mauve"\s*:\s*"[^"]+"' "$color_file" 2>/dev/null | cut -d '"' -f 4)
    c_mauve=${c_mauve:-"#cba6f7"}
    
    local c_text=$(grep -E '"text"\s*:\s*"[^"]+"' "$color_file" 2>/dev/null | cut -d '"' -f 4)
    c_text=${c_text:-"#cdd6f4"}

    # Extract a full rainbow palette
    local palette_hexes=()
    for col in red peach yellow green sapphire mauve pink; do
        local val=$(grep -E "\"$col\"\s*:\s*\"[^\"]+\"" "$color_file" 2>/dev/null | cut -d '"' -f 4)
        case $col in
            red) val=${val:-"#f38ba8"} ;;
            peach) val=${val:-"#fab387"} ;;
            yellow) val=${val:-"#f9e2af"} ;;
            green) val=${val:-"#a6e3a1"} ;;
            sapphire) val=${val:-"#74c7ec"} ;;
            mauve) val=${val:-"#cba6f7"} ;;
            pink) val=${val:-"#f5c2e7"} ;;
        esac
        palette_hexes+=("$val")
    done

    # Convert the hex codes into a printable string of ANSI truecolor circles
    local palette_str=""
    for hex in "${palette_hexes[@]}"; do
        hex="${hex//\#/}" # Strip the hash
        local r=$((16#${hex:0:2}))
        local g=$((16#${hex:2:2}))
        local b=$((16#${hex:4:2}))
        palette_str+="\\\\e[38;2;${r};${g};${b}m● \\\\e[0m"
    done

    # Check if the images directory exists and is not empty
    local image_dir="$HOME/Pictures/fastfetch"
    local logo_json=""
    
    if [ -d "$image_dir" ] && [ "$(ls -A "$image_dir" 2>/dev/null)" ]; then
        # Pick a random file from the directory
        local random_img=$(find "$image_dir" -type f | shuf -n 1)
        
        logo_json="\"logo\": {
            \"type\": \"kitty-direct\",
            \"source\": \"$random_img\",
            \"width\": 20,
            \"height\": 15,
            \"padding\": {
                \"top\": 1,
                \"left\": 2,
                \"right\": 3
            }
        },"
    else
        logo_json="\"logo\": {
            \"source\": \"nixos_small\",
            \"color\": {
                \"1\": \"$c_blue\",
                \"2\": \"$c_sapphire\"
        },
            \"padding\": {
                \"top\": 1,
                \"left\": 2,
                \"right\": 3
            }
        },"
    fi

    # Generate the dynamic Fastfetch configuration by reading the user's template
    local template_file="$HOME/.config/fastfetch/config.jsonc"
    if [ ! -f "$template_file" ]; then
        echo "Error: Fastfetch template not found at $template_file"
        return
    fi

    export TEMPLATE_FILE="$template_file"
    export OUT_FILE="$config_path"
    export c_blue c_sapphire c_teal c_mauve c_text logo_json
    python3 -c '
import os
with open(os.environ["TEMPLATE_FILE"], "r") as f:
    text = f.read()

# Replace variables if they are present in the template
text = text.replace("$c_blue", os.environ.get("c_blue", ""))
text = text.replace("$c_sapphire", os.environ.get("c_sapphire", ""))
text = text.replace("$c_teal", os.environ.get("c_teal", ""))
text = text.replace("$c_mauve", os.environ.get("c_mauve", ""))
text = text.replace("$c_text", os.environ.get("c_text", ""))

# Replace the logo placeholder
text = text.replace("\"logo_placeholder\": \"$logo_json\",", os.environ.get("logo_json", ""))

with open(os.environ["OUT_FILE"], "w") as f:
    f.write(text)
'

    # Run Fastfetch instantly using the generated config
    fastfetch -c "$config_path"
}
 
pasteimg() {
    local name="${1:-clipboard.png}"
    [[ "$name" != *.png ]] && name="$name.png"
    wl-paste --type image/png | sudo tee "$name" > /dev/null
}

stsetup() {
    local proj_dir="$HOME/Projects/stewart-new"
    
    if [[ ! -d "$proj_dir" ]]; then
        echo "Directory $proj_dir does not exist."
        return 1
    fi

    cd "$proj_dir" || return 1

    # Open a new kitty window for running the project
    kitty --directory "$proj_dir" zsh -ic "alias run='python main.py'; exec zsh" &
    
    # Open the editor in the current terminal
    zsh -ic "edit; exec zsh"
}

fetch
