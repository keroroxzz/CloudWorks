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
#include "CW_Globals.hlsl"
#include "CW_AtmosphericScatteringFunctions.hlsli"
#include "CloudWorks.hlsli"

Texture2D txScreen : register( t0 );
Texture2D txGB1 : register( t1 );
Texture2D txVolumetric : register( t2 );
#ifndef SAMLIN
#define SAMLIN
SamplerState samLinear : register( s0 );
#endif
SamplerComparisonState samShadow : register( s1 );
#ifndef CLOUD_RM_STEPS
#define CLOUD_RM_STEPS 16
#endif
#ifndef CLOUD_TO_SUN_RM_STEPS
#define CLOUD_TO_SUN_RM_STEPS 4
#endif

struct PS_QUAD_IN
{
    float4 vPosition : SV_Position;
    float4 vTexCoord : TEXCOORD0;
};

void GetNormalsAndInfDepth( Texture2D TexBuffer, SamplerState Sampler,
                            float2 TexCoords, out float ViewDepth,
                            out float3 Normals )
{
    float4 NormalSpec = TexBuffer.SampleLevel( Sampler, TexCoords, 0 );

    ViewDepth = DecodeFloatRG( NormalSpec.zw );
    ViewDepth = ViewDepth <= 0 ? 100000.0f : ViewDepth;
    Normals   = DecodeNormals( NormalSpec.xy );
    // transform normals back to world-space
    Normals = mul( Normals, (float3x3)mViewInv );
}

float4 RenderCloudsPS( PS_QUAD_IN i ) : SV_TARGET
{
    float4 OutLighting;

    const float3 ViewPos = mViewInv[3].xyz;

    // Retrieve all needed buffer samples first
    float  ViewZ;
    float3 Normals;
    GetNormalsAndInfDepth( txGB1, samLinear, i.vTexCoord.xy, ViewZ, Normals );

    float3 WorldPos = DepthToWorldPos( ViewZ, i.vTexCoord.xy ).xyz;

    float3 ViewDir  = normalize(WorldPos - ViewPos);
    float3 LightDir = normalize(vSunLightDir.xyz);
    float4 clouds = RenderClouds(ViewDir, ViewPos, LightDir, length(WorldPos-ViewPos));
    
    return clouds;
}

float4 CloudsCombinePS( PS_QUAD_IN i ) : SV_TARGET
{
    float4 OutLighting;
    
    float4 ScreenColor = txScreen.Sample( samLinear, i.vTexCoord.xy);
    float4 clouds = txVolumetric.Sample( samLinear, i.vTexCoord.xy);
	
    //Fill up the gap due to low render scale
    if(ScreenColor.a<=0.0)
    {
        const float r = 2.5;
        float3 res_vec = 0.0;
		float3 avg_col = float3(0.0, 0.0, 0.0);
        for(float a=0.0; a<6.27; a+=1.57)
        {
            float2 vec = float2(cos(a), sin(a))*r;
            float2 samp_point = i.vTexCoord.xy + vec/float2(fScreenWidth, fScreenHeight);
			float4 samp_color = txScreen.Sample(samLinear, samp_point);
            if(samp_color.a>0.0f)
            {
                res_vec.xy -= vec;
                res_vec.z += 1.0;
				
				avg_col += samp_color.rgb;
            }
        }
		
		if(res_vec.z>=4.0)
		{
			ScreenColor.rgb = avg_col/4.0f;
			ScreenColor.a = 1.0;
			
			clouds = float4(0.0, 0.0, 0.0, 1.0);
		}
        else if(res_vec.z>0.0)
        {
            res_vec.xy = normalize(res_vec.xy)*r / float2(fScreenWidth, fScreenHeight);
            clouds = txVolumetric.Sample( samLinear, i.vTexCoord.xy + res_vec.xy);
        }
    }
    
    clouds.rgb += ScreenColor.rgb*clouds.a;
	clouds.a = ScreenColor.a;
	
    return clouds;
}