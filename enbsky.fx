//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ENBSeries effect file
// visit http://enbdev.com for updates
// Copyright (c) 2007-2017 Boris Vorontsov
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/*
    GTA SA CloudWorks by Brian Tu (keroroxzz)
    Version : Alpha (3.6.5)
    Date : 2020/09/01

    Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    Contact : https://github.com/keroroxzz
*/

float4 tempF1; float4 tempF2; float4 tempF3;
float4 ScreenSize; float ENightDayFactor; float EInteriorFactor; float4 WeatherAndTime; float4 Timer;
float FieldOfView; float GameTime; float4 SunDirection; float4 CustomShaderConstants1[8]; float4 MatrixVP[4];
float4 MatrixInverseVP[4]; float4 MatrixVPRotation[4]; float4 MatrixInverseVPRotation[4]; float4 MatrixView[4];
float4 MatrixInverseView[4]; float4 CameraPosition; float4x4 MatrixWVP; float4x4 MatrixWVPInverse; float4x4 MatrixWorld;
float4x4 MatrixProj; float4 FogParam; float4 FogFarColor;

//Textures
texture2D texDepth;
texture2D texNoise;

//Sampler Inputs
sampler2D SamplerNoise = sampler_state
{
	Texture   = <texNoise>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = Wrap;
	AddressV  = Wrap;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D SamplerDepth = sampler_state
{
	Texture   = <texDepth>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
	AddressW = Wrap;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

struct VS_INPUT
{
	float3	pos : POSITION;
	float4	diff : COLOR0;
};

struct VS_OUTPUT
{
	float4	pos : POSITION;
	float4	diff : COLOR0;
	float4	vposition : TEXCOORD6;
};

VS_OUTPUT VS_Draw(VS_INPUT IN)
{
    VS_OUTPUT OUT;

	float4	pos=float4(IN.pos.x,IN.pos.y,IN.pos.z,1.0);

	float4	tpos=mul(pos, MatrixWVP);

	OUT.diff=IN.diff;
	OUT.pos=tpos;
	OUT.vposition=tpos;

    return OUT;
}

//Variables
float SunSize <string UIName="SunSize";string UIWidget="Spinner";> = { 0.4 };
float SunStrength <string UIName="SunStrength";string UIWidget="Spinner";> = { 1.0 };
float SunSpread <string UIName="SunSpread";string UIWidget="Spinner";> = { 1.0 };
float SunSpreadSmoothness <string UIName="SunSpreadSmoothness";string UIWidget="Spinner";> = { 1.0 };
float SunSetHeight <string UIName="SunSetHeight";string UIWidget="Spinner";> = { 1.0 };
float SunSetSpread <string UIName="SunSetSpread";string UIWidget="Spinner";> = { 1.0 };
float SunSetSpreadSmoothness <string UIName="SunSetSpreadSmoothness";string UIWidget="Spinner";> = { 1.0 };

float SkyTransitionAng <string UIName="SkyTransitionAngle";string UIWidget="Spinner";> = { 0.35 };
float SkySmoothness <string UIName="SkySmoothness";string UIWidget="Spinner";> = { 0.3 };

float3 S_D <string UIName="Sun Color Day";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };
float3 S_S <string UIName="Sun Color Sunset";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };
float3 ST_D <string UIName="Sky Top Color Day";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };
float3 ST_N <string UIName="Sky Top Color Night";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };
float3 ST_S <string UIName="Sky Top Color SunSet";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };
float3 SB_D <string UIName="Sky Bottom Color Day";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };
float3 SB_N <string UIName="Sky Bottom Color Night";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };
float3 SB_S <string UIName="Sky Bottom Color SunSet";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };

//just a simple one
float4 sky(const in float3 cam_dir, float moonLight, float tf)
{
    
    float
		noon_index = smoothstep(-0.1, 0.25, tf),
		sunset_index = smoothstep(0.4, 0.15, tf) * smoothstep(-0.26, -0.05, tf),
		suncross = dot(SunDirection.xyz, cam_dir);

    float3
        top = lerp(lerp(ST_N, ST_D, noon_index), ST_S, sunset_index),
        bottom = lerp(lerp(SB_N, SB_D, noon_index), SB_S, sunset_index),
        sun = lerp(S_S, S_D, noon_index),
        c = lerp(bottom, top, smoothstep(SkyTransitionAng - SkySmoothness, SkyTransitionAng + SkySmoothness, cam_dir.z));

    if (-SunSize / 1000.0 < suncross - 1)
        c = sun * suncross * SunStrength * 3.0;
    else
    {
        c += cam_dir.z * sun * exp((suncross - 1.0) / SunSpread) * SunStrength / 2.0;
        c += sunset_index * sun * exp((suncross - 1.0) / SunSetSpread) * SunStrength * smoothstep(SunSetHeight + SunSetSpreadSmoothness, SunSetHeight - SunSetSpreadSmoothness, cam_dir.z) * smoothstep(-0.2, 0.1, cam_dir.z);
    }
    c += sun * exp((suncross - 1.0) / SunSpread * 500.0) * SunStrength;
    
    return float4(c, 1.0);
}

float4 PS_Draw(VS_OUTPUT IN, float2 vPos : VPOS) : COLOR
{
    float2 
        coord = vPos.xy * ScreenSize.y;
        coord.y *= ScreenSize.z;
    
    float
        depth = tex2D(SamplerDepth, coord.xy).x,
        ti = SunDirection.z;
    
    //world pos calculation
    float4 tempvec;
    float4 worldpos;
    tempvec.xy = coord * 2.0 - 1.0;
    tempvec.y = -tempvec.y;
    tempvec.z = depth;
    tempvec.w = 1.0;
    worldpos.x = dot(tempvec, MatrixInverseVPRotation[0]);
    worldpos.y = dot(tempvec, MatrixInverseVPRotation[1]);
    worldpos.z = dot(tempvec, MatrixInverseVPRotation[2]);
    worldpos.w = dot(tempvec, MatrixInverseVPRotation[3]);
    worldpos.xyz /= worldpos.w;
    worldpos.w = 1.0;
    
    float3 direction = normalize(worldpos.xyz);

    return sky(direction, 0.0, ti);
}

technique Draw
{
    pass p0
    {
        VertexShader = compile vs_3_0 VS_Draw();
        PixelShader = compile ps_3_0 PS_Draw();
    }
}


