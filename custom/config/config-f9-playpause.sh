#!/bin/bash

# Map F9 to play-pause (F4 keeps its default microphone mute functionality)
# Note: Since FN+F9 doesn't send a detectable keycode, we'll map F9 directly
# This means F9 (without FN) will trigger play-pause, which is fine since F9 has no default function

set +e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚙️  Mapping F9 to play-pause...${NC}"

BINDINGS_CONF="$HOME/.config/hypr/bindings.conf"

# Check if bindings.conf exists, create if not
if [ ! -f "$BINDINGS_CONF" ]; then
    echo -e "${YELLOW}  Creating bindings.conf...${NC}"
    touch "$BINDINGS_CONF"
fi

# Clean up any old F4 remapping that might have been created in previous runs (idempotent cleanup)
# Only remove F4 play-pause mappings, keep F4 microphone mute functionality intact
sed -i '/# Laptop: Remap F4.*play-pause/d' "$BINDINGS_CONF"
sed -i '/bindeld.*XF86AudioMicMute.*play-pause/d' "$BINDINGS_CONF"
sed -i '/bindeld.*XF86AudioMicMute.*Play\/Pause/d' "$BINDINGS_CONF"

# Remove existing F9 play-pause mappings (idempotent: remove all instances)
sed -i '/# Laptop: Map F9.*play-pause/d' "$BINDINGS_CONF"
sed -i '/bindeld.*,F9.*play-pause/d' "$BINDINGS_CONF"
sed -i '/bindeld.*,F9.*Play\/Pause/d' "$BINDINGS_CONF"

# Check if $osdclient variable is already defined elsewhere (don't remove it, it might be used by other bindings)
OSDCLIENT_EXISTS=$(grep -q '^\$osdclient = swayosd-client.*monitor.*focused.*name' "$BINDINGS_CONF" 2>/dev/null && echo "yes" || echo "no")

# Add F9 to play-pause mapping (only if not already present)
if ! grep -q "bindeld.*,F9.*play-pause\|bindeld.*,F9.*Play/Pause" "$BINDINGS_CONF"; then
    # Add $osdclient variable if it doesn't exist
    if [ "$OSDCLIENT_EXISTS" = "no" ]; then
        cat >> "$BINDINGS_CONF" << 'EOF'

# Laptop: Map F9 to play-pause
# Since FN+F9 doesn't send a detectable keycode, F9 (without FN) is mapped instead
$osdclient = swayosd-client --monitor "$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')"
bindeld = ,F9, Play/Pause, exec, $osdclient --playerctl play-pause
EOF
    else
        # $osdclient already exists, just add the binding
        cat >> "$BINDINGS_CONF" << 'EOF'

# Laptop: Map F9 to play-pause
# Since FN+F9 doesn't send a detectable keycode, F9 (without FN) is mapped instead
bindeld = ,F9, Play/Pause, exec, $osdclient --playerctl play-pause
EOF
    fi
    echo -e "${GREEN}  ✓ Mapped F9 to play-pause${NC}"
    echo -e "${YELLOW}  ℹ️  Note: Since FN+F9 doesn't send a keycode, F9 (without FN) is mapped instead${NC}"
    echo -e "${YELLOW}     This is fine since F9 has no default function on your notebook${NC}"
else
    echo -e "${GREEN}  ✓ F9 play-pause mapping already configured${NC}"
fi
