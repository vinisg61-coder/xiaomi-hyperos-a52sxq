#ifndef INIT_SEC_H
#define INIT_SEC_H

#include <string.h>

enum device_variant {
    VARIANT_A528B = 0,
    VARIANT_A528N,
    VARIANT_MAX
};

typedef struct {
    std::string model;
    std::string codename;
} variant;

static const variant international_models = {
    .model = "SM-A528B",
    .codename = "a52sxq"
};

static const variant korean_models = {
    .model = "SM-A528N",
    .codename = "a52sxq"
};

static const variant *all_variants[VARIANT_MAX] = {
    &international_models,
    &korean_models
};

#endif // INIT_SEC_H
