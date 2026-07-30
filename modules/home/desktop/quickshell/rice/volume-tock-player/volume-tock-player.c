#include <errno.h>
#include <fcntl.h>
#include <math.h>
#include <pipewire/pipewire.h>
#include <spa/param/audio/format-utils.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define FADE_IN_MILLISECONDS 4
#define CROSSFADE_MILLISECONDS 4
#define TAIL_THRESHOLD 0.0001f
#define TAIL_FADE_MILLISECONDS 5

struct audio_sample {
    float *data;
    uint32_t channels;
    uint32_t rate;
    size_t frames;
};

struct player {
    struct pw_main_loop *main_loop;
    struct pw_loop *loop;
    struct pw_stream *stream;
    struct spa_source *completion_event;
    struct audio_sample sample;
    atomic_uint trigger_generation;
    atomic_uint completed_generation;
    unsigned int playback_generation;
    size_t playback_frame;
    size_t previous_frame;
    size_t crossfade_frame;
    size_t crossfade_frames;
    bool crossfading;
    bool completion_signaled;
    bool announced_ready;
};

static float smoothstep(float value) {
    return value * value * (3.0f - 2.0f * value);
}

static uint16_t read_be16(const uint8_t *data) {
    return ((uint16_t)data[0] << 8) | data[1];
}

static uint32_t read_be32(const uint8_t *data) {
    return ((uint32_t)data[0] << 24)
        | ((uint32_t)data[1] << 16)
        | ((uint32_t)data[2] << 8)
        | data[3];
}

static double read_extended80(const uint8_t *data) {
    const uint16_t exponent_bits = read_be16(data);
    const int sign = (exponent_bits & 0x8000) != 0 ? -1 : 1;
    const int exponent = (exponent_bits & 0x7fff) - 16383;
    uint64_t mantissa = 0;

    for (size_t index = 0; index < 8; ++index)
        mantissa = (mantissa << 8) | data[index + 2];

    if ((exponent_bits & 0x7fff) == 0 && mantissa == 0)
        return 0;

    return sign * ldexp((double)mantissa, exponent - 63);
}

static bool load_aiff(
    const char *path,
    float gain,
    struct audio_sample *sample
) {
    FILE *file = fopen(path, "rb");
    uint8_t *contents = NULL;
    bool loaded = false;

    if (file == NULL) {
        fprintf(stderr, "Could not open %s: %s\n", path, strerror(errno));
        return false;
    }

    if (fseek(file, 0, SEEK_END) != 0)
        goto cleanup;

    const long file_size = ftell(file);
    if (file_size < 12 || fseek(file, 0, SEEK_SET) != 0)
        goto cleanup;

    contents = malloc((size_t)file_size);
    if (contents == NULL)
        goto cleanup;

    if (fread(contents, 1, (size_t)file_size, file) != (size_t)file_size)
        goto cleanup;

    if (memcmp(contents, "FORM", 4) != 0
            || memcmp(contents + 8, "AIFF", 4) != 0) {
        fprintf(stderr, "%s is not an uncompressed AIFF file\n", path);
        goto cleanup;
    }

    uint32_t channels = 0;
    uint32_t frames = 0;
    uint16_t bits = 0;
    uint32_t rate = 0;
    const uint8_t *audio_data = NULL;
    size_t audio_bytes = 0;
    size_t offset = 12;

    while (offset + 8 <= (size_t)file_size) {
        const uint8_t *chunk = contents + offset;
        const uint32_t chunk_size = read_be32(chunk + 4);
        const size_t data_offset = offset + 8;

        if (data_offset + chunk_size > (size_t)file_size)
            goto cleanup;

        if (memcmp(chunk, "COMM", 4) == 0 && chunk_size >= 18) {
            const uint8_t *common = contents + data_offset;
            const double sample_rate = read_extended80(common + 8);

            channels = read_be16(common);
            frames = read_be32(common + 2);
            bits = read_be16(common + 6);
            rate = (uint32_t)llround(sample_rate);
        } else if (memcmp(chunk, "SSND", 4) == 0 && chunk_size >= 8) {
            const uint8_t *sound = contents + data_offset;
            const uint32_t sound_offset = read_be32(sound);

            if ((uint64_t)8 + sound_offset > chunk_size)
                goto cleanup;

            audio_data = sound + 8 + sound_offset;
            audio_bytes = chunk_size - 8 - sound_offset;
        }

        offset = data_offset + chunk_size + (chunk_size & 1);
    }

    if ((channels != 1 && channels != 2)
            || frames == 0
            || bits != 24
            || rate == 0
            || audio_data == NULL) {
        fprintf(
            stderr,
            "%s must be mono/stereo, 24-bit, uncompressed AIFF\n",
            path
        );
        goto cleanup;
    }

    const size_t sample_count = (size_t)frames * channels;
    if (audio_bytes < sample_count * 3)
        goto cleanup;

    sample->data = malloc(sample_count * sizeof(float));
    if (sample->data == NULL)
        goto cleanup;

    for (size_t index = 0; index < sample_count; ++index) {
        const uint8_t *encoded = audio_data + index * 3;
        int32_t value = ((int32_t)encoded[0] << 16)
            | ((int32_t)encoded[1] << 8)
            | encoded[2];

        if ((value & 0x800000) != 0)
            value |= ~0xffffff;

        sample->data[index] = gain * (float)value / 8388608.0f;
    }

    size_t final_audible_frame = 0;
    for (size_t frame = 0; frame < frames; ++frame) {
        for (size_t channel = 0; channel < channels; ++channel) {
            if (fabsf(sample->data[frame * channels + channel])
                    >= TAIL_THRESHOLD) {
                final_audible_frame = frame;
                break;
            }
        }
    }

    const size_t tail_fade_frames =
        (size_t)rate * TAIL_FADE_MILLISECONDS / 1000;
    const size_t trimmed_frames =
        final_audible_frame + 1 + tail_fade_frames < frames
            ? final_audible_frame + 1 + tail_fade_frames
            : frames;
    const size_t fade_start = trimmed_frames > tail_fade_frames
        ? trimmed_frames - tail_fade_frames
        : 0;
    const size_t fade_in_frames =
        (size_t)rate * FADE_IN_MILLISECONDS / 1000;

    for (
        size_t frame = 0;
        frame < fade_in_frames && frame < trimmed_frames;
        ++frame
    ) {
        const float progress = fade_in_frames > 1
            ? (float)frame / (float)(fade_in_frames - 1)
            : 1;
        const float fade = smoothstep(progress);

        for (size_t channel = 0; channel < channels; ++channel)
            sample->data[frame * channels + channel] *= fade;
    }

    for (size_t frame = fade_start; frame < trimmed_frames; ++frame) {
        const float progress = (float)(frame - fade_start)
            / (float)(trimmed_frames - fade_start);
        const float fade = 1.0f - smoothstep(progress);

        for (size_t channel = 0; channel < channels; ++channel)
            sample->data[frame * channels + channel] *= fade;
    }

    sample->channels = channels;
    sample->frames = trimmed_frames;
    sample->rate = rate;
    loaded = true;

cleanup:
    if (!loaded && ferror(file))
        fprintf(stderr, "Could not read %s: %s\n", path, strerror(errno));

    free(contents);
    fclose(file);
    return loaded;
}

static void on_process(void *userdata) {
    struct player *player = userdata;
    struct pw_buffer *pipewire_buffer = pw_stream_dequeue_buffer(player->stream);

    if (pipewire_buffer == NULL)
        return;

    struct spa_buffer *buffer = pipewire_buffer->buffer;
    struct spa_data *output = &buffer->datas[0];
    const size_t stride = player->sample.channels * sizeof(float);
    const size_t capacity = output->maxsize / stride;
    size_t requested = pipewire_buffer->requested;
    const unsigned int generation = atomic_load_explicit(
        &player->trigger_generation,
        memory_order_acquire
    );

    if (requested == 0 || requested > capacity)
        requested = capacity;

    if (generation != player->playback_generation
            && !player->crossfading) {
        player->crossfading =
            player->playback_generation != 0
            && player->playback_frame < player->sample.frames;
        player->previous_frame = player->playback_frame;
        player->crossfade_frame = 0;
        player->playback_generation = generation;
        player->playback_frame = 0;
        player->completion_signaled = false;
    }

    float *destination = output->data;
    if (destination == NULL) {
        pw_stream_queue_buffer(player->stream, pipewire_buffer);
        return;
    }

    memset(destination, 0, requested * stride);

    if (generation != 0 && player->playback_frame < player->sample.frames) {
        const size_t remaining =
            player->sample.frames - player->playback_frame;
        const size_t rendered = remaining < requested ? remaining : requested;

        for (size_t frame = 0; frame < rendered; ++frame) {
            float mix = 1;

            if (player->crossfading) {
                const float progress = player->crossfade_frames > 1
                    ? (float)player->crossfade_frame
                        / (float)(player->crossfade_frames - 1)
                    : 1;
                mix = smoothstep(progress);
            }

            for (
                size_t channel = 0;
                channel < player->sample.channels;
                ++channel
            ) {
                const float next_sample = player->sample.data[
                    player->playback_frame * player->sample.channels
                        + channel
                ];
                float previous_sample = 0;

                if (player->crossfading
                        && player->previous_frame
                            < player->sample.frames) {
                    previous_sample = player->sample.data[
                        player->previous_frame
                            * player->sample.channels
                            + channel
                    ];
                }

                destination[frame * player->sample.channels + channel] =
                    previous_sample * (1 - mix) + next_sample * mix;
            }

            ++player->playback_frame;

            if (player->crossfading) {
                ++player->previous_frame;
                ++player->crossfade_frame;

                if (player->crossfade_frame
                        >= player->crossfade_frames) {
                    player->crossfading = false;
                }
            }
        }
    }

    output->chunk->offset = 0;
    output->chunk->stride = (int32_t)stride;
    output->chunk->size = (uint32_t)(requested * stride);
    pw_stream_queue_buffer(player->stream, pipewire_buffer);

    if (player->playback_generation != 0
            && player->playback_frame >= player->sample.frames
            && !player->completion_signaled) {
        player->completion_signaled = true;
        atomic_store_explicit(
            &player->completed_generation,
            player->playback_generation,
            memory_order_release
        );
        pw_loop_signal_event(player->loop, player->completion_event);
    }
}

static void on_completion(void *userdata, uint64_t count) {
    struct player *player = userdata;
    const unsigned int completed = atomic_load_explicit(
        &player->completed_generation,
        memory_order_acquire
    );
    const unsigned int current = atomic_load_explicit(
        &player->trigger_generation,
        memory_order_acquire
    );

    (void)count;

    if (completed == current)
        pw_stream_set_active(player->stream, false);
}

static void trigger_playback(struct player *player) {
    atomic_fetch_add_explicit(
        &player->trigger_generation,
        1,
        memory_order_release
    );
    pw_stream_set_active(player->stream, true);
}

static void on_stdin(void *userdata, int fd, uint32_t mask) {
    struct player *player = userdata;
    char input[64];

    if ((mask & (SPA_IO_HUP | SPA_IO_ERR)) != 0) {
        pw_main_loop_quit(player->main_loop);
        return;
    }

    const ssize_t count = read(fd, input, sizeof(input));
    if (count <= 0) {
        if (count == 0 || errno != EAGAIN)
            pw_main_loop_quit(player->main_loop);
        return;
    }

    for (ssize_t index = 0; index < count; ++index) {
        if (input[index] == 'p')
            trigger_playback(player);
    }
}

static void on_stream_state_changed(
    void *userdata,
    enum pw_stream_state old_state,
    enum pw_stream_state state,
    const char *error
) {
    struct player *player = userdata;

    (void)old_state;

    if (state == PW_STREAM_STATE_ERROR) {
        fprintf(stderr, "PipeWire stream error: %s\n", error ?: "unknown");
        pw_main_loop_quit(player->main_loop);
        return;
    }

    if ((state == PW_STREAM_STATE_PAUSED
            || state == PW_STREAM_STATE_STREAMING)
            && !player->announced_ready) {
        player->announced_ready = true;
        fputs("ready\n", stdout);
        fflush(stdout);
    }
}

static void on_signal(void *userdata, int signal_number) {
    struct player *player = userdata;

    (void)signal_number;
    pw_main_loop_quit(player->main_loop);
}

static const struct pw_stream_events stream_events = {
    PW_VERSION_STREAM_EVENTS,
    .state_changed = on_stream_state_changed,
    .process = on_process,
};

int main(int argc, char **argv) {
    struct player player = {0};
    struct spa_audio_info_raw format = {0};
    uint8_t parameter_buffer[1024];
    struct spa_pod_builder builder =
        SPA_POD_BUILDER_INIT(parameter_buffer, sizeof(parameter_buffer));
    const struct spa_pod *parameters[1];
    int result = EXIT_FAILURE;

    if (argc < 3 || argc > 4) {
        fprintf(
            stderr,
            "Usage: %s SOUND.aiff GAIN [TARGET_NODE]\n",
            argv[0]
        );
        return EXIT_FAILURE;
    }

    char *gain_end = NULL;
    const float gain = strtof(argv[2], &gain_end);
    if (gain_end == argv[2]
            || *gain_end != '\0'
            || !isfinite(gain)
            || gain < 0
            || gain > 4) {
        fprintf(stderr, "GAIN must be between 0 and 4\n");
        return EXIT_FAILURE;
    }

    if (!load_aiff(argv[1], gain, &player.sample))
        return EXIT_FAILURE;

    player.crossfade_frames =
        (size_t)player.sample.rate * CROSSFADE_MILLISECONDS / 1000;

    pw_init(&argc, &argv);
    player.main_loop = pw_main_loop_new(NULL);
    if (player.main_loop == NULL)
        goto cleanup;

    player.loop = pw_main_loop_get_loop(player.main_loop);
    player.completion_event = pw_loop_add_event(
        player.loop,
        on_completion,
        &player
    );
    if (player.completion_event == NULL)
        goto cleanup;

    if (pw_loop_add_io(
            player.loop,
            STDIN_FILENO,
            SPA_IO_IN | SPA_IO_HUP | SPA_IO_ERR,
            true,
            on_stdin,
            &player
        ) == NULL) {
        goto cleanup;
    }

    pw_loop_add_signal(player.loop, SIGINT, on_signal, &player);
    pw_loop_add_signal(player.loop, SIGTERM, on_signal, &player);

    struct pw_properties *properties = pw_properties_new(
        PW_KEY_MEDIA_TYPE,
        "Audio",
        PW_KEY_MEDIA_CATEGORY,
        "Playback",
        PW_KEY_MEDIA_ROLE,
        "event",
        PW_KEY_APP_ID,
        "quickshell-volume-tock",
        PW_KEY_APP_NAME,
        "Quickshell Volume Tock",
        PW_KEY_NODE_NAME,
        "quickshell-volume-tock",
        NULL
    );

    if (argc == 4 && argv[3][0] != '\0') {
        pw_properties_set(
            properties,
            PW_KEY_TARGET_OBJECT,
            argv[3]
        );
    }

    player.stream = pw_stream_new_simple(
        player.loop,
        "quickshell-volume-tock",
        properties,
        &stream_events,
        &player
    );
    if (player.stream == NULL)
        goto cleanup;

    format.format = SPA_AUDIO_FORMAT_F32_LE;
    format.rate = player.sample.rate;
    format.channels = player.sample.channels;
    format.position[0] = player.sample.channels == 1
        ? SPA_AUDIO_CHANNEL_MONO
        : SPA_AUDIO_CHANNEL_FL;
    if (player.sample.channels == 2)
        format.position[1] = SPA_AUDIO_CHANNEL_FR;

    parameters[0] = spa_format_audio_raw_build(
        &builder,
        SPA_PARAM_EnumFormat,
        &format
    );

    if (pw_stream_connect(
            player.stream,
            PW_DIRECTION_OUTPUT,
            PW_ID_ANY,
            PW_STREAM_FLAG_AUTOCONNECT
                | PW_STREAM_FLAG_MAP_BUFFERS
                | PW_STREAM_FLAG_RT_PROCESS
                | PW_STREAM_FLAG_INACTIVE,
            parameters,
            1
        ) < 0) {
        goto cleanup;
    }

    result = pw_main_loop_run(player.main_loop) < 0
        ? EXIT_FAILURE
        : EXIT_SUCCESS;

cleanup:
    if (player.stream != NULL)
        pw_stream_destroy(player.stream);
    if (player.main_loop != NULL)
        pw_main_loop_destroy(player.main_loop);

    free(player.sample.data);
    pw_deinit();
    return result;
}
