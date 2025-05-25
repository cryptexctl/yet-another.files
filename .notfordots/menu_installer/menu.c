#include <ncurses.h>
#include <string.h>
#include <stdlib.h>
#include <locale.h>
#include <unistd.h>

#define MAX_ITEMS 7 // All, Kitty, Starship, Fastfetch, Borders, SketchyBar, Exit
#define MAX_STR_LEN 80

// --- Text Definitions (parallels install.sh get_text) ---
char texts_ru[MAX_ITEMS+2][MAX_STR_LEN] = {
    "Установщик Дотфайлов Platon", // TITLE
    "Установить все",             // OPT_ALL
    "Установить Kitty",           // OPT_KITTY
    "Установить Starship",        // OPT_STARSHIP
    "Установить Fastfetch",       // OPT_FASTFETCH
    "Установить Borders",         // OPT_BORDERS
    "Установить SketchyBar",      // OPT_SKETCHYBAR
    "Выход",                      // OPT_EXIT
    "Нажмите Enter для выбора, Q для выхода..." // HINT
};

char texts_en[MAX_ITEMS+2][MAX_STR_LEN] = {
    "Platon's Dotfiles Installer", // TITLE
    "Install All",                // OPT_ALL
    "Install Kitty",              // OPT_KITTY
    "Install Starship",           // OPT_STARSHIP
    "Install Fastfetch",          // OPT_FASTFETCH
    "Install Borders",            // OPT_BORDERS
    "Install SketchyBar",         // OPT_SKETCHYBAR
    "Exit",                       // OPT_EXIT
    "Press Enter to select, Q to quit..." // HINT
};

char (*current_texts)[MAX_STR_LEN];

void print_menu(WINDOW *menu_win, int highlight) {
    int x = 2, y = 2;
    box(menu_win, 0, 0);

    // Print title
    mvwprintw(menu_win, 0, (getmaxx(menu_win) - strlen(current_texts[0])) / 2, "%s", current_texts[0]);

    for (int i = 0; i < MAX_ITEMS; ++i) {
        if (highlight == i + 1) { // User highlight is 1-based
            wattron(menu_win, A_REVERSE);
            mvwprintw(menu_win, y, x, "%s", current_texts[i+1]);
            wattroff(menu_win, A_REVERSE);
        } else {
            mvwprintw(menu_win, y, x, "%s", current_texts[i+1]);
        }
        ++y;
    }
    // Print hint
    mvwprintw(menu_win, y + 1, (getmaxx(menu_win) - strlen(current_texts[MAX_ITEMS+1])) / 2, "%s", current_texts[MAX_ITEMS+1]);
    wrefresh(menu_win);
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <LANG_CODE> <PATH_TO_INSTALL_SCRIPT>\n", argv[0]);
        fprintf(stderr, "Example: %s RU ./install.sh\n", argv[0]);
        return 1;
    }
    char *lang_code = argv[1];
    char *install_script_path = argv[2];

    if (strcmp(lang_code, "RU") == 0) {
        current_texts = texts_ru;
    } else {
        current_texts = texts_en; // Default to EN if not RU
    }

    // Check if install.sh exists and is executable
    if (access(install_script_path, X_OK) == -1) {
        perror("Error checking install.sh");
        fprintf(stderr, "Please ensure '%s' exists and is executable.\n", install_script_path);
        return 1;
    }

    WINDOW *menu_win;
    int highlight = 1;
    int choice = 0;
    int c;

    setlocale(LC_ALL, ""); // For UTF-8 characters
    initscr();
    clear();
    noecho();
    cbreak(); // Line buffering disabled, Pass on everything
    curs_set(0); // Hide cursor

    int startx = (COLS - 40) / 2;
    int starty = (LINES - (MAX_ITEMS + 5)) / 2;

    menu_win = newwin(MAX_ITEMS + 5, 40, starty, startx);
    keypad(menu_win, TRUE);
    refresh();
    print_menu(menu_win, highlight);

    char command[256];

    while (1) {
        c = wgetch(menu_win);
        switch (c) {
            case KEY_UP:
                if (highlight == 1)
                    highlight = MAX_ITEMS;
                else
                    --highlight;
                break;
            case KEY_DOWN:
                if (highlight == MAX_ITEMS)
                    highlight = 1;
                else
                    ++highlight;
                break;
            case 10: // Enter key
                choice = highlight;
                break;
            case 'q':
            case 'Q':
                choice = MAX_ITEMS; // Corresponds to Exit
                break;
            default:
                // mvprintw(LINES - 1, 0, "Char: %d", c); // Debug key codes
                refresh();
                break;
        }
        print_menu(menu_win, highlight);
        if (choice != 0) break;
    }

    // Restore terminal before executing script
    curs_set(1);
    endwin();
    system("clear"); // Clear ncurses interface

    const char* action = NULL;
    switch (choice) {
        case 1: action = "install_all_from_make"; break;
        case 2: action = "install_kitty_from_make"; break;
        case 3: action = "install_starship_from_make"; break;
        case 4: action = "install_fastfetch_from_make"; break;
        case 5: action = "install_borders_from_make"; break;
        case 6: action = "install_sketchybar_from_make"; break;
        case 7: // Exit
            printf("%s\n", (strcmp(lang_code, "RU") == 0) ? "Выход из установщика." : "Exiting installer.");
            return 0;
    }

    if (action) {
        // Pass language to install.sh in case it needs it for direct messages (though mostly handled by C part)
        snprintf(command, sizeof(command), "bash %s %s %s", install_script_path, lang_code, action);
        printf("Executing: %s\n", command);
        int ret = system(command);
        if (ret != 0) {
            fprintf(stderr, "%s %s\n",
                (strcmp(lang_code, "RU") == 0) ? "Ошибка во время выполнения:" : "Error during execution:",
                command);
            return ret;
        }
    }
    return 0;
} 