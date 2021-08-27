#include "Globals.hlsl"

#ifndef CW_GLOBALS
#define CW_GLOBALS
static const float2 ScreenSize = float2(fScreenWidth, fScreenHeight);

#define PUDDLE_TERM vGradingColor0.b
#define PUDDLE_COVERAGE vGradingColor0.w
#define RAINNYDAY_FIX (1.0f-vGradingColor1.a)
#define RAINNY vGradingColor1.a
#define CLOUD_COVERAGE vGradingColor1.rgb

#define ATM_DENSE vGradingColor0.r*7.0f
#define MIST vGradingColor0.g
#define FOG_COLOR vHorizonCol.rgb
#define FOG_DENS fFogStart

#define TIMELAPSE
#define EXTRA_MATERIAL_FIX
#endif