#include <raylib.h>
#include <stdlib.h>

/* Only primitive ABI values cross the language boundary. */
int lab_abi_version(void) { return 3; }

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

/* GPU resources are explicitly owned by the caller, on the window thread. */
void *lab_load_texture(const char *path) {
    Texture2D texture = LoadTexture(path);
    if (!IsTextureValid(texture)) return NULL;
    Texture2D *handle = malloc(sizeof(*handle));
    if (!handle) {
        UnloadTexture(texture);
        return NULL;
    }
    *handle = texture;
    SetTextureFilter(texture, TEXTURE_FILTER_POINT);
    return handle;
}

void lab_unload_texture(void *handle) {
    if (!handle) return;
    Texture2D *texture = handle;
    UnloadTexture(*texture);
    free(texture);
}

void lab_draw_texture(void *handle, int x, int y, int scale) {
    Texture2D *texture = handle;
    DrawTextureEx(*texture, (Vector2){(float)x, (float)y}, 0.0f,
                  (float)scale, WHITE);
}

int lab_open_audio(void) {
    InitAudioDevice();
    return IsAudioDeviceReady() ? 1 : 0;
}

void lab_close_audio(void) { CloseAudioDevice(); }
int lab_sound_trigger(void) { return IsKeyPressed(KEY_SPACE) ? 1 : 0; }

void *lab_load_sound(const char *path) {
    Sound sound = LoadSound(path);
    if (!IsSoundValid(sound)) return NULL;
    Sound *handle = malloc(sizeof(*handle));
    if (!handle) {
        UnloadSound(sound);
        return NULL;
    }
    *handle = sound;
    return handle;
}

void lab_unload_sound(void *handle) {
    if (!handle) return;
    Sound *sound = handle;
    UnloadSound(*sound);
    free(sound);
}

void lab_play_sound(void *handle) { PlaySound(*(Sound *)handle); }
