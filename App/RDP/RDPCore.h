/* SPDX-License-Identifier: GPL-2.0-or-later
 * mRemoteNXT — Copyright (c) 2026 Razvan Cremenescu
 * See LICENSE for full text.
 */

// Interfata pur C peste FreeRDP. NU include headere Foundation/Cocoa aici, ca sa nu
// se loveasca typedef-ul IID al WinPR de cel din CoreFoundation (CFPlugInCOM).
#ifndef RDPCORE_H
#define RDPCORE_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct RDPCore RDPCore;

typedef struct {
    void (*onConnected)(void *ctx, int width, int height);
    // bgra = buffer live (valid doar in timpul apelului); consumatorul copiaza sincron.
    void (*onImage)(void *ctx, const uint8_t *bgra, int width, int height, int stride);
    void (*onDisconnected)(void *ctx, const char *error); // error == NULL => normal
} RDPCoreCallbacks;

// Coduri taste speciale (trebuie sa coincida cu RDPSpecialKey din RDPClient.h).
enum {
    RDPCORE_KEY_ENTER = 1, RDPCORE_KEY_BACKSPACE, RDPCORE_KEY_TAB, RDPCORE_KEY_ESCAPE,
    RDPCORE_KEY_SPACE, RDPCORE_KEY_UP, RDPCORE_KEY_DOWN, RDPCORE_KEY_LEFT, RDPCORE_KEY_RIGHT,
    RDPCORE_KEY_DELETE, RDPCORE_KEY_SHIFT, RDPCORE_KEY_CONTROL, RDPCORE_KEY_ALT, RDPCORE_KEY_COMMAND
};

RDPCore *rdpcore_create(const char *host, int port, const char *user,
                        const char *domain, const char *pass,
                        int width, int height, int scalePercent,
                        RDPCoreCallbacks cb, void *ctx);
void rdpcore_start(RDPCore *core);
void rdpcore_stop(RDPCore *core);
void rdpcore_free(RDPCore *core);
// Redimensionare live a desktop-ului RDP (canalul Display Control).
void rdpcore_resize(RDPCore *core, int width, int height, int scalePercent);

void rdpcore_mouse_move(RDPCore *core, int x, int y);
void rdpcore_mouse_button(RDPCore *core, int button, bool down, int x, int y);
void rdpcore_scroll(RDPCore *core, int steps, int x, int y);
void rdpcore_key_unicode(RDPCore *core, uint16_t unicode, bool down);
void rdpcore_key_special(RDPCore *core, int key, bool down);

#ifdef __cplusplus
}
#endif

#endif
