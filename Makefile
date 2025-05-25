\
SHELL := /bin/bash
BASE_DIR := $(shell pwd)
INSTALL_SCRIPT := $(BASE_DIR)/install.sh
NOTFORDOTS_DIR := $(BASE_DIR)/.notfordots
MENU_C_DIR := $(NOTFORDOTS_DIR)/menu_installer
MENU_C_SRC := $(MENU_C_DIR)/menu.c
MENU_C_BIN := $(MENU_C_DIR)/menu_installer
CC := gcc
# Try to find ncurses, first with pkg-config (more robust), then common flags
NCURSES_CFLAGS := $(shell PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/opt/homebrew/opt/ncurses/lib/pkgconfig pkg-config --cflags ncursesw 2>/dev/null || echo "-I/opt/homebrew/opt/ncurses/include")
NCURSES_LDFLAGS := $(shell PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/opt/homebrew/opt/ncurses/lib/pkgconfig pkg-config --libs ncursesw 2>/dev/null || echo "-L/opt/homebrew/opt/ncurses/lib -lncursesw")

# If pkg-config failed for ncursesw and direct paths also might be problematic, fallback to system ncurses
ifeq ($(strip $(NCURSES_LDFLAGS)),"-L/opt/homebrew/opt/ncurses/lib -lncursesw") # Check if it's the default fallback
    ifeq ($(shell brew --prefix ncurses 2>/dev/null && echo TRUE), TRUE) # Check if ncurses is installed via brew
        # If brew ncurses exists, assume it's good.
    else
        # If brew ncurses is not found, try system's ncurses (usually just -lncurses)
        NCURSES_CFLAGS :=
        NCURSES_LDFLAGS := -lncurses
    endif
endif


CFLAGS_MENU := $(NCURSES_CFLAGS) -Wall
LDFLAGS_MENU := $(NCURSES_LDFLAGS)

# Detect language
SYS_LANG := $(shell if [[ "$(LANG)" == ru* ]]; then echo "RU"; else echo "EN"; fi)

.PHONY: all install_all install_sketchybar menuconfig clean help

help:
	@echo "Available targets:"
	@echo "  all                Install all dotfiles (default via install_all)."
	@echo "  install_all        Install all dotfiles using install.sh."
	@echo "  install_sketchybar Install only SketchyBar configuration using install.sh."
	@echo "  menuconfig         Show an interactive ncurses menu to select components."
	@echo "  clean              Clean compiled files for menuconfig."
	@echo "  help               Show this help message."

all: install_all

# Ensure install.sh is executable before running targets that use it
$(INSTALL_SCRIPT):
	@chmod +x $(INSTALL_SCRIPT)

install_all: $(INSTALL_SCRIPT)
	@echo "Installing all configurations via Makefile..."
	@$(INSTALL_SCRIPT) install_all_from_make

install_sketchybar: $(INSTALL_SCRIPT)
	@echo "Installing SketchyBar via Makefile..."
	@$(INSTALL_SCRIPT) install_sketchybar_from_make

# --- Menuconfig related targets ---
$(MENU_C_BIN): $(MENU_C_SRC) $(INSTALL_SCRIPT)
	@mkdir -p $(MENU_C_DIR)
	@echo "Compiling ncurses menu installer ($(MENU_C_SRC))..."
	$(CC) $(CFLAGS_MENU) -o $@ $< $(LDFLAGS_MENU)
	@echo "Ncurses menu installer compiled to $(MENU_C_BIN)"

menuconfig: $(MENU_C_BIN)
	@echo "Launching ncurses menu installer..."
	@$(MENU_C_BIN) $(SYS_LANG) $(INSTALL_SCRIPT)

clean:
	@echo "Cleaning compiled menu installer..."
	@rm -f $(MENU_C_BIN)
	@echo "Cleaning backup files..."
	@find $(HOME)/.config -name "*.bak_*" -print -delete
	@echo "Done."

# Create .notfordots/menu_installer directory if source file exists
$(MENU_C_DIR):
	@mkdir -p $(MENU_C_DIR)

# Ensure the source file exists before trying to compile
$(MENU_C_SRC): | $(MENU_C_DIR)
	# This rule is just to ensure the directory exists if the source is added.
	# The actual creation of menu.c is handled by the assistant.
	@if [ ! -f "$(MENU_C_SRC)" ]; then \\
		echo "Warning: $(MENU_C_SRC) not found. Please create it or ensure it's generated."; \\
	fi 