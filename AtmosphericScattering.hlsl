/*===================================================================================
Serendipity 1.0 (GTA RenderHook Preset)
	by Brian Tu (RTU)
	2021/7/26

This is a modified shader file from original RH preset.

Credit : 
	RenderHook by PetkaGTA
===================================================================================*/

#include "GBuffer.hlsl"
#include "GameMath.hlsl"
#include "CW_AtmosphericScatteringFunctions.hlsli"
#ifndef ATMOPHERIC_SCATTERING
#define ATMOPHERIC_SCATTERING

struct PS_QUAD_IN
{
    float4 vPosition : SV_Position;
    float4 vTexCoord : TEXCOORD0;
};

Texture2D txScreen : register(t0);
Texture2D txGB1 : register(t1);
Texture2D txShadow : register(t3);
#ifndef SAMLIN
#define SAMLIN
SamplerState samLinear : register(s0);
#endif
SamplerComparisonState samShadow : register(s1);

float4 AtmosphericScatteringPS(PS_QUAD_IN i) : SV_Target
{
    float4 ScreenColor = txScreen.Sample(samLinear, i.vTexCoord.xy);
    
    const float3 ViewPos = mViewInv[3].xyz;
    float3 WorldPos = DepthToWorldPos( 100000.0f, i.vTexCoord.xy ).xyz;
    float3 ViewDir  = normalize(WorldPos - ViewPos);
    
    if(ScreenColor.a<=0.0)
    {
        ScreenColor.rgb = OutterSpace(ViewDir, vSunLightDir.xyz);
        ScreenColor.rgb = Sky(ScreenColor.rgb, Game2Atm_Alt(ViewPos), ViewDir, vSunLightDir.xyz, earth);
    }
    
    return ScreenColor;
}

#endif