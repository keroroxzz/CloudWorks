/*===================================================================================
GTA SA - CloudWorks Alpha 4.0
by Brian Tu (RTU)

See my Github page for more information:
https://github.com/keroroxzz

2021/7/25

License :　Creative Commons　Attribution-NonCommercial-ShareAlike 3.0 Unported
===================================================================================*/

#include "CW_Globals.hlsl"

#ifndef NOISE_GEN
#define NOISE_GEN

static float randomSeed = 1618.03398875;

float hash(float n) {
    return frac(sin(n/1873.1873) * randomSeed);
}

float noise2d(float3 p) {

    float3 fr = floor(p),
    ft = frac(p);

    float n = 1153.0 * fr.x + 2381.0 * fr.y + p.z,
    nr = n + 1153.0,
    nd = n + 2381.0,
    no = nr + 2381.0,

    v = hash(n),
    vr = hash(nr),
    vd = hash(nd),
    vo = hash(no);

    return ((v * (1.0 - ft.x) + vr * (ft.x)) * (1.0 - ft.y) + (vd * (1.0 - ft.x) + vo * ft.x) * ft.y);
}

float noise3d(float3 p) {

    float3 fr = floor(p),
    ft = frac(p);

    float n = 1153.0 * fr.x + 2381.0 * fr.y + fr.z,
    nr = n + 1153.0,
    nd = n + 2381.0,
    no = nr + 2381.0,

    v = lerp(hash(n), hash(n + 1.0), ft.z),
    vr = lerp(hash(nr), hash(nr + 1.0), ft.z),
    vd = lerp(hash(nd), hash(nd + 1.0), ft.z),
    vo = lerp(hash(no), hash(no + 1.0), ft.z);

    return lerp(lerp(v,vr,ft.x), lerp(vd,vo,ft.x),ft.y);
}

float noise3d_timedep(float3 p, float time) {

    float3 fr = floor(p),
    ft = frac(p);

    float n = 1153.0 * fr.x + 2381.0 * fr.y + fr.z + time,
    nr = n + 1153.0,
    nd = n + 2381.0,
    no = nr + 2381.0,

    v = lerp(hash(n), hash(n + 1.0), ft.z),
    vr = lerp(hash(nr), hash(nr + 1.0), ft.z),
    vd = lerp(hash(nd), hash(nd + 1.0), ft.z),
    vo = lerp(hash(no), hash(no + 1.0), ft.z);

    return lerp(lerp(v,vr,ft.x), lerp(vd,vo,ft.x),ft.y);
}

inline float map(float x, float a, float b, float c, float d) {
    return (x - b) / (a - b) * (c - d) + d;
}

inline float clampMap(float x, float a, float b, float c, float d) {
    return saturate((x - b) / (a - b)) * (c - d) + d;
}

float PuddleNoise(float3 p, float3 Normals, float rainny, float puddle_term, float coverage)
{
    p.z/=8.0;
    p/=5.0f;
    float n = noise3d(p)*0.5f;
    n += noise3d(2.0f*p)*0.25f;
    n += noise3d(6.0f*p)*0.125f;
    
    float fac = saturate(2.0f*n-0.5f)*2.0f;
    n += noise3d(32.0f*p)*0.0625f*fac;
    n += noise3d(128.0f*p)*0.0625f*fac;
    
    n = (1.0-n) * clampMap(Normals.z, 1.0-rainny, -rainny, 1.0, 0.0);
    return smoothstep(0.58f, 1.0f - 0.35f*puddle_term, n + coverage - 0.5) * puddle_term;
}

#endif
