#include <raylib.h>
#include <stdlib.h>

/* Only primitive ABI values cross the language boundary. */
int lab_abi_version(void) { return 6; }

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

int lab_mouse_x(void) { return GetMouseX(); }
int lab_mouse_y(void) { return GetMouseY(); }
int lab_mouse_pressed(void) { return IsMouseButtonPressed(MOUSE_BUTTON_LEFT) ? 1 : 0; }
int lab_mouse_released(void) { return IsMouseButtonReleased(MOUSE_BUTTON_LEFT) ? 1 : 0; }
int lab_rotate_pressed(void) { return IsKeyPressed(KEY_R) ? 1 : 0; }
int lab_cancel_pressed(void) { return IsKeyPressed(KEY_C) ? 1 : 0; }

void lab_draw_object(int x, int y, int w, int h, int color, int turn, int held) {
    const Color palette[] = {
        {115, 79, 53, 255}, {49, 120, 131, 255},
        {220, 166, 83, 255}, {150, 93, 135, 255}
    };
    Color fill = palette[(unsigned int)color % 4];
    DrawRectangle(x, y, w, h, fill);
    DrawRectangleLines(x, y, w, h, held ? YELLOW : RAYWHITE);
    /* A corner marker rotates with the object's footprint. */
    int mx = x + ((turn == 1 || turn == 2) ? w - 12 : 4);
    int my = y + ((turn == 2 || turn == 3) ? h - 12 : 4);
    DrawRectangle(mx, my, 8, 8, RAYWHITE);
}

void lab_draw_object_label(const char *label, int x, int y) {
    DrawText(label, x, y, 16, RAYWHITE);
}

void lab_sound_volume(void *handle, float volume) {
    SetSoundVolume(*(Sound *)handle, volume);
}
void lab_stop_sound(void *handle) { StopSound(*(Sound *)handle); }
int lab_sound_playing(void *handle) { return IsSoundPlaying(*(Sound *)handle) ? 1 : 0; }

void *lab_load_music(const char *path) {
    Music music = LoadMusicStream(path);
    if (!IsMusicValid(music)) return NULL;
    Music *handle = malloc(sizeof(*handle));
    if (!handle) {
        UnloadMusicStream(music);
        return NULL;
    }
    music.looping = true;
    *handle = music;
    return handle;
}
void lab_unload_music(void *handle) {
    if (!handle) return;
    UnloadMusicStream(*(Music *)handle);
    free(handle);
}
void lab_play_music(void *handle) { PlayMusicStream(*(Music *)handle); }
void lab_stop_music(void *handle) { StopMusicStream(*(Music *)handle); }
void lab_update_music(void *handle) { UpdateMusicStream(*(Music *)handle); }
void lab_music_volume(void *handle, float volume) { SetMusicVolume(*(Music *)handle, volume); }
int lab_music_playing(void *handle) { return IsMusicStreamPlaying(*(Music *)handle) ? 1 : 0; }
float lab_music_length(void *handle) { return GetMusicTimeLength(*(Music *)handle); }
float lab_music_time(void *handle) { return GetMusicTimePlayed(*(Music *)handle); }
int lab_music_looping(void *handle) { return ((Music *)handle)->looping ? 1 : 0; }
int lab_audio_toggle(void) { return IsKeyPressed(KEY_M) ? 1 : 0; }
int lab_audio_mute(void) { return IsKeyPressed(KEY_V) ? 1 : 0; }
int lab_audio_volume_delta(void) { return IsKeyPressed(KEY_UP) - IsKeyPressed(KEY_DOWN); }

void lab_target_fps(int fps) { SetTargetFPS(fps); }
