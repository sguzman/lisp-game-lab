#include <raylib.h>

/* Only primitive ABI values cross the language boundary. */
int lab_abi_version(void) { return 1; }

int lab_open(int width, int height, const char *title) {
    InitWindow(width, height, title);
    if (!IsWindowReady()) return 0;
    SetTargetFPS(60);
    return 1;
}

void lab_close(void) { CloseWindow(); }
int lab_should_close(void) { return WindowShouldClose() ? 1 : 0; }
int lab_input_x(void) { return IsKeyDown(KEY_RIGHT) - IsKeyDown(KEY_LEFT); }
int lab_input_y(void) { return IsKeyDown(KEY_DOWN) - IsKeyDown(KEY_UP); }

void lab_begin(void) {
    BeginDrawing();
    ClearBackground((Color){27, 33, 45, 255});
}

void lab_end(void) { EndDrawing(); }

void lab_draw_item(int x, int y, int size) {
    DrawRectangle(x, y, size, size, (Color){236, 180, 92, 255});
    DrawRectangleLines(x, y, size, size, RAYWHITE);
}

void lab_draw_label(const char *label) {
    DrawText(label, 20, 20, 20, RAYWHITE);
}
