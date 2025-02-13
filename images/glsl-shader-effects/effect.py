#!/usr/bin/env python3

# Disable pygame AVX2 warning
import warnings

warnings.filterwarnings("ignore", category=RuntimeWarning, message=".*AVX2.*")

import os
import argparse

from PIL import Image

from processing import *  # noqa: F403
from processing.main import codes


shaders = {}


# Get all constants
def get_constants():
    global shaders

    for code in codes:
        constant_name = [name for name, value in globals().items() if value == code][0]
        shaders[code] = constant_name

    shaders = sorted(shaders.items(), key=lambda x: x[0])


# List all available effects
def list_effects():
    global shaders

    for code, constant_name in shaders:
        print(f"{code:2}: {constant_name}")


# Apply effects to image
def apply_effect(image_path, *effects):
    effect_names = effects_path(*effects)

    # Load the image
    image = Image.open(image_path)

    # Apply shaders
    process = Process(*effects)  # noqa: F405
    tex = process.run(image)

    # Save result to PIL img
    pil_img = tex.toImage()
    if pil_img.mode == "RGBA":
        pil_img = pil_img.convert("RGB")

    # Save image
    filename, file_extension = os.path.splitext(image_path)
    output_image_name = f"{filename}_{effect_names}{file_extension}"

    print("Saving image to", output_image_name)

    pil_img.save(output_image_name)

    return output_image_name


# Delete image with effects
def delete_image(image_path, *effects):
    effect_names = effects_path(*effects)

    # Save image
    filename, file_extension = os.path.splitext(image_path)
    output_image_name = f"{filename}_{effect_names}{file_extension}"

    print("deleting image to", output_image_name)

    return output_image_name


def effects_path(*effects):
    global shaders
    # Trouver les noms des constantes correspondantes aux numéros
    constant_names = [shaders[effect][1] for effect in effects]

    # Concaténer les noms en minuscules et séparés par '_'
    path_string = "_".join(constant_names).lower()

    return path_string


def main():
    # Créer le parser principal
    parser = argparse.ArgumentParser(description="Apply EGA palette effect on image")

    # Créer un sous-parser pour les sous-commandes
    subparsers = parser.add_subparsers(dest="command")

    # List command
    subparsers.add_parser("list", help="List all available effects")

    # Apply command
    apply_parser = subparsers.add_parser("apply", help="Apply effects to an image")
    apply_parser.add_argument(
        "effects",
        type=int,
        nargs="+",
        help="List of effects (1 2 3), see value witch ./effect.py list",
    )
    apply_parser.add_argument("image", type=str, help="Image filename")

    # Delete command
    apply_parser = subparsers.add_parser("delete", help="Delete image with effects")
    apply_parser.add_argument(
        "effects",
        type=int,
        nargs="+",
        help="List of effects (1 2 3), see value witch ./effect.py list",
    )
    apply_parser.add_argument("image", type=str, help="Image filename")

    # Parse les arguments
    args = parser.parse_args()

    # Parse commands
    get_constants()
    if args.command == "list":
        list_effects()
    elif args.command == "apply":
        apply_effect(args.image, *args.effects)
    elif args.command == "delete":
        delete_image(args.image, *args.effects)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
