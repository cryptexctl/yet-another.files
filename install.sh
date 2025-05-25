#!/bin/bash

# --- Configuration ---
CONFIG_DIR_BASE="$HOME/.config"
BACKUP_SUFFIX=".bak_$(date +%Y%m%d_%H%M%S)"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# --- Language Detection (can be overridden by Makefile) ---
SYS_LANG="EN" # Default to English
if [[ -z "$1" || ( "$1" != "install_all_from_make" && "$1" != "install_sketchybar_from_make" && "$1" != "install_kitty_from_make" && "$1" != "install_starship_from_make" && "$1" != "install_fastfetch_from_make" && "$1" != "install_borders_from_make" ) ]]; then
    # Only run language detection if not called with a specific make target
    if [[ "$LANG" == ru* ]]; then
        SYS_LANG="RU"
    fi
elif [[ "$1" == "RU" || "$1" == "EN" ]]; then # Language passed as first arg by C program
    SYS_LANG="$1"
fi

# --- Text Definitions ---
get_text() {
    local key="$1"
    if [[ "$SYS_LANG" == "RU" ]]; then
        case "$key" in
            "WELCOME") echo "Добро пожаловать в установщик дотфайлов!" ;;
            "MENU_TITLE") echo "Выберите опцию:" ;;
            "OPT_ALL") echo "1. Установить все" ;;
            "OPT_BAR") echo "2. Установить только SketchyBar" ;;
            "OPT_EXIT") echo "3. Выход" ;;
            "PROMPT") echo "Введите ваш выбор [1-3]: " ;;
            "INVALID_CHOICE") echo "Неверный выбор. Пожалуйста, попробуйте снова." ;;
            "OS_ERROR") echo "Ошибка: Этот скрипт предназначен только для macOS." ;;
            "INSTALLING") echo "Установка" ;;
            "BACKING_UP") echo "Создание резервной копии для" ;;
            "TO") echo "в" ;;
            "DONE_SUFFIX") echo "установлен(а)." ;;
            "NOT_FOUND_ERROR") echo "Ошибка:" ;;
            "NOT_FOUND_SUFFIX") echo "не найден(а) в" ;;
            "EXITING") echo "Выход..." ;;
            "ALL_INSTALLED_SUCCESS") echo "Установка всех конфигураций завершена." ;;
            "SKETCHYBAR_INSTALLED_SUCCESS") echo "SketchyBar установлен." ;;
            "SKETCHYBAR_NAME") echo "SketchyBar" ;;
            "KITTY_NAME") echo "Kitty" ;;
            "STARSHIP_NAME") echo "Starship" ;;
            "FASTFETCH_NAME") echo "Fastfetch" ;;
            "BORDERS_NAME") echo "Borders" ;;
            *) echo "RU Text key '$key' not found" >&2; exit 1 ;;
        esac
    else # English texts
        case "$key" in
            "WELCOME") echo "Welcome to the dotfiles installer!" ;;
            "MENU_TITLE") echo "Select an option:" ;;
            "OPT_ALL") echo "1. Install All" ;;
            "OPT_BAR") echo "2. Install Only SketchyBar" ;;
            "OPT_EXIT") echo "3. Exit" ;;
            "PROMPT") echo "Enter your choice [1-3]: " ;;
            "INVALID_CHOICE") echo "Invalid choice. Please try again." ;;
            "OS_ERROR") echo "Error: This script is intended for macOS only." ;;
            "INSTALLING") echo "Installing" ;;
            "BACKING_UP") echo "Backing up" ;;
            "TO") echo "to" ;;
            "DONE_SUFFIX") echo "installed." ;;
            "NOT_FOUND_ERROR") echo "Error:" ;;
            "NOT_FOUND_SUFFIX") echo "not found at" ;;
            "EXITING") echo "Exiting..." ;;
            "ALL_INSTALLED_SUCCESS") echo "All configurations installed." ;;
            "SKETCHYBAR_INSTALLED_SUCCESS") echo "SketchyBar installed." ;;
            "SKETCHYBAR_NAME") echo "SketchyBar" ;;
            "KITTY_NAME") echo "Kitty" ;;
            "STARSHIP_NAME") echo "Starship" ;;
            "FASTFETCH_NAME") echo "Fastfetch" ;;
            "BORDERS_NAME") echo "Borders" ;;
            *) echo "EN Text key '$key' not found" >&2; exit 1 ;;
        esac
    fi
}

# --- Helper Functions ---
check_os() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        echo -e "$(get_text "OS_ERROR")"
        exit 1
    fi
}

install_config_dir() {
    local app_name_text_key="$1"
    local src_subdir="$2"
    local dest_config_name="$3"
    local app_name_msg="$(get_text "$app_name_text_key")"
    local src_path="$SCRIPT_DIR/$src_subdir"
    local dest_path_target_dir="$CONFIG_DIR_BASE/$dest_config_name"
    echo -e "\n$(get_text "INSTALLING") $app_name_msg..."
    if [ ! -d "$src_path" ]; then
        echo "  $(get_text "NOT_FOUND_ERROR") $app_name_msg $(get_text "NOT_FOUND_SUFFIX") $src_path"
        return 1
    fi
    mkdir -p "$(dirname "$dest_path_target_dir")"
    if [ -e "$dest_path_target_dir" ]; then
        echo "  $(get_text "BACKING_UP") $dest_path_target_dir $(get_text "TO") $dest_path_target_dir$BACKUP_SUFFIX"
        mv "$dest_path_target_dir" "$dest_path_target_dir$BACKUP_SUFFIX"
    fi
    echo "  $(get_text "INSTALLING") $app_name_msg $(get_text "TO") $dest_path_target_dir"
    mkdir -p "$dest_path_target_dir"
    cp -R "$src_path/." "$dest_path_target_dir/"
    echo "  $app_name_msg $(get_text "DONE_SUFFIX")"
}

install_config_file() {
    local app_name_text_key="$1"
    local src_file_rel_path="$2"
    local dest_file_full_path="$3"
    local app_name_msg="$(get_text "$app_name_text_key")"
    local src_path="$SCRIPT_DIR/$src_file_rel_path"
    echo -e "\n$(get_text "INSTALLING") $app_name_msg..."
    if [ ! -f "$src_path" ]; then
        echo "  $(get_text "NOT_FOUND_ERROR") $app_name_msg $(get_text "NOT_FOUND_SUFFIX") $src_path"
        return 1
    fi
    mkdir -p "$(dirname "$dest_file_full_path")"
    if [ -e "$dest_file_full_path" ]; then
        echo "  $(get_text "BACKING_UP") $dest_file_full_path $(get_text "TO") $dest_file_full_path$BACKUP_SUFFIX"
        mv "$dest_file_full_path" "$dest_file_full_path$BACKUP_SUFFIX"
    fi
    echo "  $(get_text "INSTALLING") $app_name_msg $(get_text "TO") $dest_file_full_path"
    cp "$src_path" "$dest_file_full_path"
    echo "  $app_name_msg $(get_text "DONE_SUFFIX")"
}

# --- Installation Functions ---
install_kitty() {
    install_config_dir "KITTY_NAME" "kitty" "kitty"
}
install_starship() {
    install_config_file "STARSHIP_NAME" "starship.toml" "$CONFIG_DIR_BASE/starship.toml"
}
install_fastfetch() {
    install_config_dir "FASTFETCH_NAME" "fastfetch" "fastfetch"
}
install_borders() {
    install_config_file "BORDERS_NAME" "borders/bordersrc" "$CONFIG_DIR_BASE/borders/bordersrc"
}
install_sketchybar() {
    install_config_dir "SKETCHYBAR_NAME" "sketchybar" "sketchybar"
}

# --- Main Logic ---
check_os # Exit if not macOS

ACTION="$1"

if [[ -z "$ACTION" || ( "$ACTION" != "install_all_from_make" && "$ACTION" != "install_sketchybar_from_make" && "$ACTION" != "install_kitty_from_make" && "$ACTION" != "install_starship_from_make" && "$ACTION" != "install_fastfetch_from_make" && "$ACTION" != "install_borders_from_make" ) ]]; then
    # Interactive mode if no specific action from make or C program
    if [[ "$ACTION" == "RU" || "$ACTION" == "EN" ]]; then # Lang passed by C program but no other action
      ACTION="interactive" # Fallback to interactive if only lang is passed
    else 
      SYS_LANG="EN" # Default lang for direct script run without params
      if [[ "$LANG" == ru* ]]; then SYS_LANG="RU"; fi
    fi

    echo -e "$(get_text "WELCOME")\n"
    while true; do
        echo "$(get_text "MENU_TITLE")"
        echo "$(get_text "OPT_ALL")"
        echo "$(get_text "OPT_BAR")"
        echo "$(get_text "OPT_EXIT")"
        read -r -p "$(get_text "PROMPT")" choice
        case $choice in
            1) ACTION="install_all"; break ;; 
            2) ACTION="install_sketchybar"; break ;; 
            3) echo -e "\n$(get_text "EXITING")"; exit 0 ;; 
            *) echo -e "\n$(get_text "INVALID_CHOICE")\n" ;; 
        esac
    done
fi

case "$ACTION" in
    "install_all" | "install_all_from_make")
        install_kitty
        install_starship
        install_fastfetch
        install_borders
        install_sketchybar
        echo -e "\n$(get_text "ALL_INSTALLED_SUCCESS")"
        ;;
    "install_sketchybar" | "install_sketchybar_from_make")
        install_sketchybar
        echo -e "\n$(get_text "SKETCHYBAR_INSTALLED_SUCCESS")"
        ;;
    "install_kitty_from_make") install_kitty ;; 
    "install_starship_from_make") install_starship ;; 
    "install_fastfetch_from_make") install_fastfetch ;; 
    "install_borders_from_make") install_borders ;; 
    "interactive") # This case is handled by the loop above, just to prevent unknown action error
        ;;
    # No default case needed as interactive mode handles invalid initial args
    # and specific actions are pre-validated.
esac

exit 0 