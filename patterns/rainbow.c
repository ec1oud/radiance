#include <math.h>
#include <stdlib.h>

#include "core/err.h"
#include "core/slot.h"
#include "patterns/pattern.h"
#include "patterns/static.h"
#include "util/color.h"
#include "util/math.h"
#include "util/siggen.h"
#include "util/signal.h"

// --------- Pattern: Template -----------

typedef struct {
    struct freq_state freq_state;
    enum osc_type type;
    float kx;
    float ky;
} state_t;

enum param_names {
    TYPE,
    OMEGA,
    K_MAG,
    K_ANGLE,

    N_PARAMS
};

static parameter_t params[] = {
    [TYPE] = {
        .name = "Wave Type",
        .default_val = 0.21,
        .val_to_str = osc_quantize_parameter_label,
    },
    [OMEGA] = {
        .name = "\\omega",
        .default_val = 0.4,
        .val_to_str = power_quantize_parameter_label,
    },
    [K_MAG] = {
        .name = "|k|",
        .default_val = 0.5,
        .val_to_str = float_to_string,
    },
    [K_ANGLE] = {
        .name = "<)k",
        .default_val = 0.5,
        .val_to_str = float_to_string,
    },
};

static pat_state_pt init() {
    state_t * state = malloc(sizeof(state_t));
    freq_init(&state->freq_state, 0.5, 0);
    state->type = OSC_SINE;
    state->kx = 1.0;
    state->ky = 0.0;
    return state;
}

static void del(pat_state_pt state) {
    free(state);
}

static void update(slot_t* slot, mbeat_t t) {
    state_t * state = (state_t *) slot->state;
    state->type = quantize_parameter(osc_quant_labels, param_state_get(&slot->param_states[TYPE]));
    freq_update(&state->freq_state, t, param_state_get(&slot->param_states[OMEGA]));

    float k_mag;
    float k_ang;
    k_mag = param_state_get(&slot->param_states[K_MAG]);
    k_ang = param_state_get(&slot->param_states[K_ANGLE]) * 2 * M_PI;
    state->kx = COS(k_ang) * k_mag;
    state->ky = SIN(k_ang) * k_mag;
}

static color_t pixel(slot_t* slot, float x, float y) {
    state_t * state = (state_t *) slot->state;
    float t = osc_fn_gen(state->type, state->freq_state.phase + y * state->ky + x * state->kx);
    struct colormap * cm = slot->colormap ? slot->colormap : cm_global;
    return colormap_color(cm, t);
}

static int event(slot_t* slot, enum pat_event event, float event_data){
    state_t * state = (state_t *) slot->state;
    if(isnan(event_data)) return 0;
    UNUSED(event);
    UNUSED(state);
    // TEMPLATE: Handle click/MIDI event
    return 0;
}

pattern_t pat_rainbow = {
    .render = &pixel,
    .init = &init,
    .del = &del,
    .update = &update,
    .event = &event,
    .n_params = N_PARAMS,
    .parameters = params,
    .name = "Rainbow",
};