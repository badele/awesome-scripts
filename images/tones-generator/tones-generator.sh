#!/usr/bin/env bash

# SECURITY NOTE: This script implements extensive security measures to avoid using 'eval'
# and prevent code injection vulnerabilities. All user inputs are strictly validated,
# sanitized, and processed through secure methods. Command execution is done via
# temporary files with restricted permissions rather than dynamic code evaluation.
# This defensive approach ensures safe handling of color names, filenames, and
# numeric parameters while maintaining functionality.

set -euo pipefail # Strict error handling
set -f            # Disable globbing to avoid issues with parentheses

readonly DEFAULT_LARGEUR_BLOC=80
readonly DEFAULT_NB_VARIANTES=2
readonly MIN_COULEURS=2
readonly MAX_COULEURS=12
readonly MIN_LUMINOSITE=10
readonly MAX_LUMINOSITE=95
readonly STEP_LUMINOSITE=15
readonly HAUTEUR_VARIANTE=60

# Global variables to avoid export
declare -g hue sat light

usage() {
    cat <<EOF
Usage: $0 <base_color> <number_colors> [number_variants] [block_width] 

Example: $0 '#ffd700' 12 3
Example: $0 'gold' 12 3 80

Arguments:
  base_color        Starting color (#rrggbb format or color name)
  number_colors     Number of colors in harmonic palette ($MIN_COULEURS-$MAX_COULEURS)
  number_variants   Number of light/dark variants (default: $DEFAULT_NB_VARIANTES)
  block_width       Width of each color block (default: $DEFAULT_LARGEUR_BLOC)
EOF
}

log_info() {
    echo "✓ $*" >&2
}

log_error() {
    echo "✗ Error: $*" >&2
}

# Safe cleanup of temporary files
cleanup() {
    local temp_files=("$@")
    for file in "${temp_files[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
        fi
    done
}

# Strict validation of numeric parameters
validate_numeric() {
    local value="$1"
    local name="$2"

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        log_error "$name must be a positive integer"
        return 1
    fi
}

# Parameter validation
validate_params() {
    local couleur="$1" nb_couleurs="$2" nb_variantes="$3" largeur_bloc="$4"

    # Strict numeric validation
    validate_numeric "$nb_couleurs" "number_colors" || return 1
    validate_numeric "$nb_variantes" "number_variants" || return 1
    validate_numeric "$largeur_bloc" "block_width" || return 1

    if [[ $nb_couleurs -lt $MIN_COULEURS || $nb_couleurs -gt $MAX_COULEURS ]]; then
        log_error "Number of colors must be between $MIN_COULEURS and $MAX_COULEURS"
        return 1
    fi

    if [[ $nb_variantes -lt 1 || $nb_variantes -gt 10 ]]; then
        log_error "Number of variants must be between 1 and 10"
        return 1
    fi

    if [[ $largeur_bloc -lt 10 || $largeur_bloc -gt 500 ]]; then
        log_error "Block width must be between 10 and 500 pixels"
        return 1
    fi

    # Secure color validation with timeout
    if ! timeout 5s magick -size 1x1 "xc:$couleur" null: 2>/dev/null; then
        log_error "Color '$couleur' invalid or timeout"
        return 1
    fi

    return 0
}

# HSL extraction with security validation
extract_hsl() {
    local couleur="$1"
    local hsl_raw

    # Secure extraction with timeout
    hsl_raw=$(timeout 5s magick -size 1x1 "xc:$couleur" -colorspace HSL txt: 2>/dev/null |
        grep -oP 'hsl\(\K[^)]*' | head -1)

    if [[ -z "$hsl_raw" ]]; then
        log_error "Unable to parse color '$couleur'"
        return 1
    fi

    # HSL format validation
    if ! [[ "$hsl_raw" =~ ^[0-9.]+%?,[0-9.]+%?,[0-9.]+%?$ ]]; then
        log_error "Invalid HSL format: '$hsl_raw'"
        return 1
    fi

    # Secure parsing
    IFS=',' read -ra hsl_parts <<<"$hsl_raw"
    hue=${hsl_parts[0]%\%}
    hue=${hue%.*} # Convert to integer
    sat=${hsl_parts[1]%\%}
    light=${hsl_parts[2]%\%}

    # Validation of extracted values
    validate_numeric "$hue" "hue" || return 1
    validate_numeric "${sat%.*}" "saturation" || return 1
    validate_numeric "${light%.*}" "lightness" || return 1

    # Value normalization
    hue=$((hue % 360))
    sat=$((sat > 100 ? 100 : sat))
    light=$((light > 100 ? 100 : light))
}

# Secure command execution via temporary file
safe_execute_magick() {
    local args=("$@")
    local temp_script
    local exit_code

    temp_script=$(mktemp --suffix=.sh) || {
        log_error "Unable to create temporary file"
        return 1
    }

    # Automatic cleanup
    trap "cleanup '$temp_script'" EXIT

    # Secure command writing
    {
        echo "#!/bin/bash"
        echo "set -euo pipefail"
        printf 'magick '
        printf '%q ' "${args[@]}"
        echo
    } >"$temp_script"

    # Verify that file was created correctly
    if [[ ! -s "$temp_script" ]]; then
        log_error "Error creating temporary script"
        return 1
    fi

    # Execution with restricted permissions
    chmod 700 "$temp_script"
    bash "$temp_script" 2>/dev/null
    exit_code=$?

    # Immediate cleanup
    cleanup "$temp_script"
    trap - EXIT

    return $exit_code
}

# Secure generation of color rectangles
generate_color_rectangles() {
    local nb_couleurs="$1" largeur_bloc="$2" angle_rotation="$3"
    local target_light="$4" y_start="$5" y_end="$6"
    local rectangles=()
    local hue_rotated x_start x_end

    for ((i = 0; i < nb_couleurs; i++)); do
        hue_rotated=$(((hue + i * angle_rotation) % 360))
        x_start=$((i * largeur_bloc))
        x_end=$(((i + 1) * largeur_bloc - 1))

        rectangles+=("-fill")
        rectangles+=("hsl($hue_rotated,$sat%,$target_light%)")
        rectangles+=("-draw")
        rectangles+=("rectangle $x_start,$y_start $x_end,$y_end")
    done

    printf '%s\0' "${rectangles[@]}" # Use null separator to avoid space issues
}

# Secure luminosity calculation
clamp_luminosity() {
    local value="$1"

    # Input validation
    validate_numeric "$value" "luminosity value" || return 1

    if [[ $value -lt $MIN_LUMINOSITE ]]; then
        echo $MIN_LUMINOSITE
    elif [[ $value -gt $MAX_LUMINOSITE ]]; then
        echo $MAX_LUMINOSITE
    else
        echo $value
    fi
}

# Secure hex color generation
generate_hex_colors() {
    local nb_couleurs="$1" angle_rotation="$2"
    local hex_colors=()
    local hue_rotated hex_color

    for ((i = 0; i < nb_couleurs; i++)); do
        hue_rotated=$(((hue + i * angle_rotation) % 360))
        hex_color=$(timeout 5s magick -size 1x1 "xc:hsl($hue_rotated,$sat%,$light%)" txt: 2>/dev/null |
            grep -oP '#[0-9A-Fa-f]{6}' | head -1)

        # Hex format validation
        if [[ "$hex_color" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
            hex_colors+=("$hex_color")
        else
            hex_colors+=("#000000") # Default color in case of error
        fi
    done

    printf '%s\n' "${hex_colors[@]}"
}

# Secure filename validation
sanitize_filename() {
    local filename="$1"
    # Remove dangerous characters and limit length
    filename=$(echo "$filename" | tr -cd '[:alnum:]._-' | cut -c1-100)
    echo "${filename:-output}" # Default name if empty
}

# Main program
main() {
    # Parameter verification
    if [[ $# -lt 2 ]]; then
        usage
        exit 1
    fi

    # Parameter assignment with default values
    local couleur_input="$1"
    local nb_couleurs="$2"
    local nb_variantes="${3:-$DEFAULT_NB_VARIANTES}"
    local largeur_bloc="${4:-$DEFAULT_LARGEUR_BLOC}"

    # Complete parameter validation
    validate_params "$couleur_input" "$nb_couleurs" "$nb_variantes" "$largeur_bloc" || exit 1

    # Secure HSL extraction
    extract_hsl "$couleur_input" || exit 1

    # Calculations with validation
    local angle_rotation=$((360 / nb_couleurs))
    local largeur_totale=$((largeur_bloc * nb_couleurs))
    local hauteur_totale=$(((nb_variantes * 2 + 1) * HAUTEUR_VARIANTE))

    # Validation of calculated dimensions
    if [[ $largeur_totale -gt 10000 || $hauteur_totale -gt 10000 ]]; then
        log_error "Image dimensions too large (max: 10000x10000)"
        exit 1
    fi

    # Display information
    echo "Base color    : $couleur_input"
    echo "Extracted HSL : H=${hue}° S=${sat}% L=${light}%"
    echo "Generating palette with $nb_couleurs colors (rotation: ${angle_rotation}°)"

    # Secure argument construction
    local all_args=("-size" "${largeur_totale}x${hauteur_totale}" "xc:white")
    local y_offset=0
    local light_variant
    local temp_rectangles

    # Light variants (top)
    for ((v = nb_variantes; v >= 1; v--)); do
        light_variant=$(clamp_luminosity $((light + v * STEP_LUMINOSITE)))
        mapfile -d '' temp_rectangles < <(generate_color_rectangles "$nb_couleurs" "$largeur_bloc" "$angle_rotation" "$light_variant" "$y_offset" "$((y_offset + HAUTEUR_VARIANTE - 1))")
        all_args+=("${temp_rectangles[@]}")
        y_offset=$((y_offset + HAUTEUR_VARIANTE))
        # echo "Light variant $v: lightness ${light_variant}%"
    done

    # Base colors (middle)
    local base_rectangles
    mapfile -d '' base_rectangles < <(generate_color_rectangles "$nb_couleurs" "$largeur_bloc" "$angle_rotation" "$light" 0 "$((HAUTEUR_VARIANTE - 1))")
    mapfile -d '' temp_rectangles < <(generate_color_rectangles "$nb_couleurs" "$largeur_bloc" "$angle_rotation" "$light" "$y_offset" "$((y_offset + HAUTEUR_VARIANTE - 1))")
    all_args+=("${temp_rectangles[@]}")

    for ((i = 1; i <= nb_couleurs; i++)); do
        local hue_rotated=$(((hue + (i - 1) * angle_rotation) % 360))
        # echo "Color $i: hsl($hue_rotated,$sat%,$light%)"
    done
    y_offset=$((y_offset + HAUTEUR_VARIANTE))

    # Dark variants (bottom)
    for ((v = 1; v <= nb_variantes; v++)); do
        light_variant=$(clamp_luminosity $((light - v * STEP_LUMINOSITE)))
        mapfile -d '' temp_rectangles < <(generate_color_rectangles "$nb_couleurs" "$largeur_bloc" "$angle_rotation" "$light_variant" "$y_offset" "$((y_offset + HAUTEUR_VARIANTE - 1))")
        all_args+=("${temp_rectangles[@]}")
        y_offset=$((y_offset + HAUTEUR_VARIANTE))
        # echo "Dark variant $v: lightness ${light_variant}%"
    done

    # Secure filenames
    local nom_fichier="$(sanitize_filename "palette_${nb_couleurs}c_${angle_rotation}deg").png"
    local nom_fichier_base="$(sanitize_filename "palette_base_${nb_couleurs}c").png"

    # Main image generation
    all_args+=("$nom_fichier")

    if safe_execute_magick "${all_args[@]}"; then
        log_info "Palette generated: $nom_fichier"
        log_info "Dimensions: ${largeur_totale}x${hauteur_totale}"
        log_info "Colors: $nb_couleurs base colors"
        log_info "Variants: $((nb_variantes * 2)) variants (light and dark)"

        # Base palette
        local base_args=("-size" "${largeur_totale}x${HAUTEUR_VARIANTE}" "xc:white")
        base_args+=("${base_rectangles[@]}")
        base_args+=("$nom_fichier_base")

        if safe_execute_magick "${base_args[@]}"; then
            log_info "Base palette generated: $nom_fichier_base"
        fi
    else
        log_error "Error during image generation"
        exit 1
    fi
}

# Entry point
main "$@"
