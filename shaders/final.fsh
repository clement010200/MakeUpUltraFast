#version 120
/* MakeUp Ultra Fast - composite.fsh
Render: Vertical blur pass and final renderer

Javier Garduño - GNU Lesser General Public License v3.0
*/

// Do not remove ¡It works!
/*
const int colortex0Format = R11F_G11F_B10F;
const int colortex1Format = R8;
const int colortex2Format = RGB8;
const int colortex3Format = R8;
const int gaux1Format = RGBA16F;
const int gaux2Format = RGB8;
const int colortex6Format = R8;
const int colortex7Format = R8;

const bool colortex0Clear = false;
const bool colortex1Clear = false;
const bool colortex2Clear = false;
const bool colortex3Clear = false;
const bool colortex4Clear = false;
const bool colortex5Clear = false;
const bool colortex6Clear = false;
const bool colortex7Clear = false;
*/

// Redefined constants
const int noiseTextureResolution = 128;
const float ambientOcclusionLevel = 1.0f;
const float eyeBrightnessHalflife = 10.0f;
const float centerDepthHalflife = 2.0f;

#define DOF 1  // [0 1] Enables depth of field

// 'Global' constants from system
uniform sampler2D colortex0;

#if DOF == 1
  uniform sampler2D gaux1;
  // uniform sampler2D gaux2;
  uniform float pixelSizeY;
  uniform float viewHeight;
  uniform float pixelSizeX;
  uniform float viewWeight;
#endif

// Varyings (per thread shared variables)
varying vec2 texcoord;

#if DOF == 1
  #include "/lib/blur.glsl"
#endif

void main() {

  #if DOF == 1
    vec4 color_blur = texture2D(gaux1, texcoord);
    float blur_radius = color_blur.a;
    vec3 color = color_blur.rgb;

    if (blur_radius > 0.5) {
      float radius_inv = 1.0 / blur_radius;

      vec4 average = vec4(0.0);
      float start  = max(texcoord.y - blur_radius * pixelSizeY,       pixelSizeY * 0.5);
      float finish = min(texcoord.y + blur_radius * pixelSizeY, 1.0 - pixelSizeY * 0.5);
      float step = pixelSizeY * .5;
      if (blur_radius > 3.0) {
        step *= 4.0;
      } else if (blur_radius > 1.0) {
        step *= 1.0;
      }

      for (float y = start; y <= finish; y += step) {
        float weight = fogify((y - texcoord.y) * viewHeight * radius_inv, 0.35);
        vec4 new_blur = texture2D(gaux1, vec2(texcoord.x, y));
        weight *= new_blur.a * radius_inv;
        average.rgb += new_blur.rgb * weight;
        average.a += weight;
      }
      color = average.rgb / average.a;
    }

    gl_FragColor = vec4(color, 1.0);

  #else
    gl_FragColor = texture2D(colortex0, texcoord);
  #endif
}
