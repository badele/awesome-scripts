# GLSL Shader effects

This script use the excelent https://github.com/gBloxy/Image-Processing project

## Usage

When you apply several shaders, the name of the file is created in function of
the shaders used.

```shell
nix develop or nix run "github:badele/awesome-scripts?dir=images/glsl-shader-effects"


# List all available shaders
./effect.py list 

# Apply shaders 30 and 1 (VGA_PALETTE and CRT)
./effect.py apply 30,1 <imagename>
# or with spaces (requires quotes)
./effect.py apply "30 1" <imagename>
# or with find command
find <path> -type f \( -iname "*.png" -o -iname "*.jpeg" -o -iname "*.jpg" \) -not -name "*_ega_palette.*" | xargs -I {} ./effect.py apply 30,1 {}
```

## Sample result

**Original image**

![Original](./Amiga-500-Ads-2-588x800.jpg)

**Effects**

![Monochrome](./Amiga-500-Ads-2-588x800_monochrome_palette_crt.jpg)

_./Amiga-500-Ads-2-588x800_monochrome_palette_crt.jpg_

![CGA](./Amiga-500-Ads-2-588x800_cga_palette_crt.jpg)

_./Amiga-500-Ads-2-588x800_cga_palette_crt.jpg_

![EGA](./Amiga-500-Ads-2-588x800_ega_palette_crt.jpg)

_./Amiga-500-Ads-2-588x800_ega_palette_crt.jpg_

![VGA](./Amiga-500-Ads-2-588x800_vga_palette_crt.jpg)

_./Amiga-500-Ads-2-588x800_vga_palette_crt.jpg_
