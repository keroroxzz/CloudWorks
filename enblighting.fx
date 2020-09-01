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

float4 tempF1;
float4 tempF2;
float4 tempF3;
float4 ScreenSize;
float4 Timer;
float ENightDayFactor;
float4 SunDirection;
float EInteriorFactor;
float FadeFactor;
float FieldOfView;
float4 MatrixVP[4];
float4 MatrixInverseVP[4];
float4 MatrixVPRotation[4];
float4 MatrixInverseVPRotation[4];
float4 MatrixView[4];
float4 MatrixInverseView[4];
float4 CameraPosition;
float GameTime;
float4 CustomShaderConstants1[8];
float4 WeatherAndTime;
float4 FogFarColor;

//Textures
texture2D texColor;
texture2D texDepth;
texture2D texDistri < string ResourceName="distribution.png";>;

//Sampler 
sampler2D SamplerColor = sampler_state
{
    Texture = <texColor>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU = Clamp;
    AddressV = Clamp;
    SRGBTexture = TRUE;
    MaxMipLevel = 2;
    MipMapLodBias = 0;
};

sampler2D SamplerDepth = sampler_state
{
    Texture = <texDepth>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
    AddressW = Wrap;
    SRGBTexture = TRUE;
    MaxMipLevel = 1;
    MipMapLodBias = 0;
};

sampler2D SamplerDis = sampler_state
{
    Texture = <texDistri>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
    AddressW = Wrap;
    SRGBTexture = FALSE;
    MaxMipLevel = 16;
    MipMapLodBias = 0;
};

//VS Post
struct VS_OUTPUT_POST
{
    float4 vpos : POSITION;
    float2 txcoord : TEXCOORD0;
};

struct VS_INPUT_POST
{
    float3 pos : POSITION;
    float2 txcoord : TEXCOORD0;
};

VS_OUTPUT_POST VS_PostProcess(VS_INPUT_POST IN)
{
    VS_OUTPUT_POST OUT;
    float4 pos = float4(IN.pos.x, IN.pos.y, IN.pos.z, 1.0);
    
    OUT.vpos = pos;
    OUT.txcoord.xy = IN.txcoord.xy;
    
    return OUT;
}

//Variables
float vb_t <string UIName="VolumeBox_top";string UIWidget="Spinner";>;
float vb_b <string UIName="VolumeBox_bottom";string UIWidget="Spinner";>;
float min_sl <string UIName="MinStepLength";string UIWidget="Spinner";> = { 1.0 };
float max_sl <string UIName="MaxStepLength";string UIWidget="Spinner";> = { 40.0 };
float step_mul <string UIName="StepLengthMultiplyer";string UIWidget="Spinner";> = { 3.0 };
float maxStep <string UIName="MaxStep";string UIWidget="Spinner";> = { 100.0 };
float dCut <string UIName="DensityCut";string UIWidget="Spinner";> = { 0.0 };
float tCut <string UIName="TransparencyCut";string UIWidget="Spinner";> = { 0.01 };

float body_top <string UIName="BodyTop";string UIWidget="Spinner";> = { 0.8 };
float body_mid <string UIName="BodyMiddle";string UIWidget="Spinner";> = { 0.4 };
float body_bot <string UIName="BodyBottom";string UIWidget="Spinner";> = { 0.2 };
float body_thickness <string UIName="BodyThickness";string UIWidget="Spinner";> = { 0.0 };

float grow <string UIName="DensityIncrease";string UIWidget="Spinner";> = { 1.0 };
float grow_c <string UIName="DensityIncrease_cloudy";string UIWidget="Spinner";> = { 1.0 };

float soft_top <string UIName="DensitySoftnessTop";string UIWidget="Spinner";> = { 40.0 };
float soft_bot <string UIName="DensitySoftnessBottom";string UIWidget="Spinner";> = { 40.0 };
float soft_bot_c <string UIName="DensitySoftnessBottom_cloudy";string UIWidget="Spinner";> = { 40.0 };

float noise_densA <string UIName="ChunkDensityA";string UIWidget="Spinner";> = { 0.43 };
float noise_densB <string UIName="ChunkDensityB";string UIWidget="Spinner";> = { 1.02 };
float noise_densC <string UIName="DetailDensityC";string UIWidget="Spinner";> = { 0.30 };
float noise_densD <string UIName="DetailDensityD";string UIWidget="Spinner";> = { 0.87 };
float noise_densE <string UIName="DetailDensityE";string UIWidget="Spinner";> = { 0.87 };
float noiseSizeA <string UIName="ChunkSizeA";string UIWidget="Spinner";> = { 48.6 };
float noiseSizeB <string UIName="ChunkSizeB";string UIWidget="Spinner";> = { 7.75 };
float noiseSizeC <string UIName="DetailSizeC";string UIWidget="Spinner";> = { 0.33 };
float noiseSizeD <string UIName="DetailSizeD";string UIWidget="Spinner";> = { 0.54 };
float noiseSizeE <string UIName="DetailSizeE";string UIWidget="Spinner";> = { 0.54 };

float temp1 <string UIName="temp1";string UIWidget="Spinner";> = { 1.0 };
float temp2 <string UIName="temp2";string UIWidget="Spinner";> = { 1.0 };

float3 cloud_shift <string UIName="shift";string UIWidget="Vector";> = { 0.0, 0.0, 0.0 };

float curvy_scale <string UIName="curvy_scale";string UIWidget="Spinner";> = { 2.5 };
float curvy_ang <string UIName="curvy_ang";string UIWidget="Spinner";> = { 2.5 };
float curvy_strength <string UIName="curvy_strength";string UIWidget="Spinner";> = { 2.5 };

float BeerFactor <string UIName="BeerFactor";string UIWidget="Spinner";> = { 0.0 };
float EffectFactor <string UIName="EffectFactor";string UIWidget="Spinner";> = { 2.5 };
float CloudSoftness <string UIName="CloudSoftness";string UIWidget="Spinner";> = { 0.0 };

float scattering <string UIName="ScatteringRange";string UIWidget="Spinner";> = { 0.0 };
float scatteringStrength <string UIName="ScatteringStrength";string UIWidget="Spinner";> = { 0.0 };
float moonlight_strength <string UIName="MoonStrength";string UIWidget="Spinner";> = { 0.0 };

float CloudContrast <string UIName="CloudContrast";string UIWidget="Spinner";> = { 0.0 };
float cloudBrightnessMultiply <string UIName="CloudBrightnessMultiply";string UIWidget="Spinner";> = { 2.5 };

float ShadowStepLength <string UIName="ShadowStepLength";string UIWidget="Spinner";> = { 10.0 };
float DetailShadowStepLength <string UIName="DetailShadowStepLength";string UIWidget="Spinner";> = { 10.0 };
float ShadowDetail <string UIName="DetailShadowStrength";string UIWidget="Spinner";> = { 1.0 };
float shadowExpand <string UIName="ShadowExpand";string UIWidget="Spinner";> = { 0 };
float shadowStrength <string UIName="ShadowStrength";string UIWidget="Spinner";> = { 1 };
float shadowContrast <string UIName="ShadowContrast";string UIWidget="Spinner";> = { 1 };
float shadowSoftness <string UIName="ShadowSoftness";string UIWidget="Spinner";> = { 0 };

float fogEffect <string UIName="FogEffect";string UIWidget="Spinner";> = { 0 };
float fogEffect_c <string UIName="FogEffect_cloudy";string UIWidget="Spinner";> = { 0 };

float alpha_curve <string UIName="AlphaCurve";string UIWidget="Spinner";> = { 2.5 };
float fade_s <string UIName="FadeStart";string UIWidget="Spinner";> = { 0.0 };
float fade_e <string UIName="FadeEnd";string UIWidget="Spinner";> = { 2.5 };

float Atomesphere_Distance <string UIName="AtomesphereDistance";string UIWidget="Spinner";> = { 1000.0 };
float Atomesphere_Smoothness <string UIName="AtomesphereSmoothness";string UIWidget="Spinner";> = { 1000.0 };
float3 Atomesphere <string UIName="Atomesphere";string UIWidget="Vector";> = { 0.0, 0.0, 0.0 };

float speed <string UIName="Speed";string UIWidget="Spinner";> = { 0.0 };
float3 nA_move <string UIName="NoiseA_Direction";string UIWidget="Vector";> = { 0.0, 0.0, 0.0 };
float3 nB_move <string UIName="NoiseB_Direction";string UIWidget="Vector";> = { 0.0, 0.0, 0.0 };
float3 nC_move <string UIName="NoiseC_Direction";string UIWidget="Vector";> = { 0.0, 0.0, 0.0 };
float3 nD_move <string UIName="NoiseD_Direction";string UIWidget="Vector";> = { 0.0, 0.0, 0.0 };

float3 CBC_D <string UIName="Cloud Dark Color Day";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };
float3 CBC_N <string UIName="Cloud Dark Color Night";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };
float3 CBC_S <string UIName="Cloud Dark Color SunSet";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };
float3 CBC_CD <string UIName="Cloud Dark Color Cloudy Day";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };
float3 CBC_CN <string UIName="Cloud Dark Color Cloudy Night";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };

float3 CTC_D <string UIName="Cloud Bright Color Day";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };
float3 CTC_N <string UIName="Cloud Bright Color Night";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };
float3 CTC_S <string UIName="Cloud Bright Color SunSet";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };
float3 CTC_CD <string UIName="Cloud Bright Color Cloudy Day";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };
float3 CTC_CN <string UIName="Cloud Bright Color Cloudy Night";string UIWidget="Color";> = { 0.0, 0.0, 0.0 };

float grow_h <string UIName="fatnessH";string UIWidget="Spinner";> = { 1.0 };
float softness_h <string UIName="softnessH";string UIWidget="Spinner";> = { 40.0 };
float H_scaleA <string UIName="HscaleA";string UIWidget="Spinner";> = { 40.0 };
float H_scaleB <string UIName="HscaleB";string UIWidget="Spinner";> = { 40.0 };
float curvy_scale_h <string UIName="curvy_scale_h";string UIWidget="Spinner";> = { 2.5 };
float curvy_ang_h <string UIName="curvy_ang_h";string UIWidget="Spinner";> = { 2.5 };
float curvy_strength_h <string UIName="curvy_strength_h";string UIWidget="Spinner";> = { 2.5 };
float H_noise_densA <string UIName="HdensA";string UIWidget="Spinner";> = { 40.0 };
float H_noise_densB <string UIName="HdensB";string UIWidget="Spinner";> = { 40.0 };
float3 H_nA_move <string UIName="H_NoiseA_Direction";string UIWidget="Vector";> = { 0.0, 0.0, 0.0 };
float3 H_nB_move <string UIName="H_NoiseB_Direction";string UIWidget="Vector";> = { 0.0, 0.0, 0.0 };

#define nsA		0.0005/noiseSizeA
#define nsB		0.0005/noiseSizeB
#define nsC		0.1/noiseSizeC
#define nsD		0.1/noiseSizeD
#define nsE		0.1/noiseSizeE

float3 PosOnPlane(const in float3 origin, const in float3 direction, const in float h, inout float dis)
{
    dis = (h - origin.z) / direction.z;
    
    return float3((origin + direction * dis).xy, h);
}

float3 PosOnSphere(const in float3 o, const in float3 d, const in float h, const in float r, inout float distance)
{
    float d1 = -h * d.z,
    d2 = sqrt(r * r - (h * h - d1 * d1));
    distance = d1 + d2;
    return o + d * distance;
}

float clampMap(float x, float a, float b, float c, float d)
{
    return clamp((x - b) / (a - b), 0.0, 1.0) * (c - d) + d;

}

float4 cloud_shape(float z, float4 profile, float3 dens_thres)
{
    float soft = clampMap(z, profile.y, profile.x, dens_thres.z, dens_thres.y);
    
    return
        float4(
        smoothstep(profile.z, lerp(profile.y, profile.z, profile.w), z) * smoothstep(profile.x, lerp(profile.y, profile.x, profile.w), z),
        dens_thres.x + soft,
        dens_thres.x - soft,
        soft);
}

//============IQ's noise===================
//This noise generator is developed by Inigo Quilez.
//License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
float hash(float n)
{
    return frac(sin(n) * 9487.5987);
}

float noise_p(float3 p)
{
    float3 fr = floor(p),
       ft = frac(p);
    
    
    float n = 3.0 * fr.x + 17.0 * fr.y + fr.z,
        nr = n + 3.0,
        nd = n + 17.0,
        no = nr + 17.0,
        
        v = lerp(hash(n), hash(n + 1.0), ft.z),
        vr = lerp(hash(nr), hash(nr + 1.0), ft.z),
        vd = lerp(hash(nd), hash(nd + 1.0), ft.z),
        vo = lerp(hash(no), hash(no + 1.0), ft.z);
    
    return ((v * (1.0 - ft.x) + vr * (ft.x)) * (1.0 - ft.y) +
        (vd * (1.0 - ft.x) + vo * ft.x) * ft.y);
}
//=========================================

float noise_d(const in float2 xy)
{
    return tex2Dlod(SamplerDis, float4(xy, 0.0, 0.0)).r;
}

//large chunk for the distribution of clouds.
float chunk(in float3 pos, const in float3 offsetA, const in float3 offsetB, in float cs)
{
    pos += cloud_shift * pos.z;
    float2
		pA = pos.xy + offsetA.xy,
		pB = pos.xy + offsetB.xy;

    return clamp((noise_densA * noise_d(pA * nsA) + noise_densB * noise_d(pB * nsB)) * cs, 0.0, 1.0);
}

//Detial noise for clouds
float detial(const in float3 pos, const in float3 offsetC, const in float3 offsetD)
{
    float3
		pC = pos + offsetC,
		pD = pos + offsetD;
    
    float nc = noise_p(pC * nsC);
    
    //curvy distortion
    float a = nc * curvy_ang;
    float3 d = float3(cos(a), sin(a), 0.0) * curvy_strength;
    
    float dens = noise_densC * nc + noise_densD * (1.0 - noise_p((pD + d) * nsD)) + noise_densE * noise_p((pD + d / 2) * nsE);
	
    return dens;
}

float detial2(const in float3 pos, const in float3 offsetC)
{
    float3
		pC = pos + offsetC;
	
    return noise_densC * noise_p(pC * nsC) * 2.0;
}

//one step marching for lighting
float brightness(float3 p, float4 profile, float3 dens_thres, const in float3 offsetA, const in float3 offsetB, const in float3 offsetC)
{
    float3
        p1 = p + SunDirection.xyz * ShadowStepLength,
        p2 = p + SunDirection.xyz * DetailShadowStepLength;
    
    float4
        cs = cloud_shape(p1.z, profile, dens_thres);
        
    float
        dens1 = chunk(p1, offsetA, offsetB, cs.x),
		dens2 = detial2(p2, offsetC) * ShadowDetail,
    
    d = (dens1 + dens2) * shadowContrast + shadowExpand - (cs.z - shadowSoftness);
    d /= (cs.w + shadowSoftness) * 2.0;
        
    return 1.0 - clamp(d, 0.0, 1.0) * shadowStrength;
}

float4 Cloud_mid(const in float3 cam_dir, in float3 p, in float dist, const in float depth, float time, float moonLight, float tf, float sunny)
{
    float4 d = float4(0.0, 0.0, 0.0, min_sl); //distance, distance factor, gap, the last march step
    
    p = PosOnPlane(p, cam_dir, clamp(p.z, vb_b, vb_t), d.x);
    d.y = d.x;
    
    if (d.x >= 0.0 && d.x < fade_e)
    {
        float
            fe = lerp(fogEffect_c, fogEffect, sunny) / 100.0;
        
        float3
			flowA = -time * nA_move,
			flowB = -time * nB_move,
			flowC = -time * nC_move,
			flowD = -time * nD_move,
        
            dens_thres = float3(
                1.0 / lerp(grow_c, grow, sunny),
                soft_top,
                lerp(soft_bot_c, soft_bot, sunny)),
        
            fx = float3(0.5, 0.0, 1.0); //brightness, density, transparency
            
        float4 profile = float4(body_top, body_mid, body_bot, body_thickness);
        
        if (depth == 1)
            dist = fade_e;
        
        for (int i = 0.0; fx.z > 0.0 && p.z <= vb_t && p.z >= vb_b && i < maxStep && d.x - d.w < dist; i += 1.0)
        {
            float3 cs = cloud_shape(p.z, profile, dens_thres).xyz;
            
            float
                dens = (chunk(p, flowA, flowB, cs.x) + temp2) * (detial(p, flowC, flowD) + temp1) / (1 + temp2) / (1 + temp1),
                marchStep = clampMap(dens, cs.z, dCut, min_sl, max_sl) * clampMap(d.x, 0.0, 10000.0, 1.0, step_mul), 
			    coverage = smoothstep(cs.z, cs.y, dens) * marchStep / CloudSoftness,
                ds = fx.z + fe;
            
            //fade into near objects
            if (d.x >= dist)
            {
                coverage *= d.z / d.w;
                fx.y += fe * d.z / d.w;
            }
            else
                fx.y += fe;
            
            ds *= coverage / EffectFactor;
            fx.x = lerp(fx.x, brightness(p, profile, dens_thres, flowA, flowB, flowC), ds);
            d.y = d.y * (1.0 - ds) + ds * d.x;
            
            fx.y += coverage;
            fx.z = (exp(-fx.y / BeerFactor) - tCut) / (1.0 - tCut);
            
            d.z = dist - d.x;
            
            //marching
            p += cam_dir * marchStep;
            d.x += marchStep;
            d.w = marchStep;
        }
        
        if (fx.y > 0.0)
        {
            float
			    noon_index = smoothstep(-0.09, 0.3, tf),
			    sunset_index = smoothstep(0.3, 0.1, tf) * smoothstep(-0.18, -0.08, tf),
			    suncross = dot(SunDirection.xyz, cam_dir);
            
            float3
			    c_dark = lerp(lerp(lerp(CBC_CN, CBC_CD, noon_index), lerp(CBC_N, CBC_D, noon_index), sunny), CBC_S, sunset_index),
			    c_bright = lerp(lerp(lerp(CTC_CN, CTC_CD, noon_index), lerp(CTC_N, CTC_D, noon_index), sunny), CTC_S, sunset_index) * cloudBrightnessMultiply;
            
            c_bright += normalize(c_bright) * scatteringStrength * exp((suncross - 1.0) / scattering) * (smoothstep(-0.13, -0.08, tf));
            
            float3 C = lerp(c_dark, c_bright, smoothstep(0.0, 1.0, (fx.x - 0.5) * CloudContrast + 0.5));
            
            float rsf = smoothstep(Atomesphere_Distance - Atomesphere_Smoothness, Atomesphere_Distance + Atomesphere_Smoothness, d.y);
            C += Atomesphere / 100.0 * rsf;

		    //fading
            fx.y = 1.0 - exp(-fx.y / alpha_curve);
            fx.y *= smoothstep(fade_e, fade_s, d.y);
            return float4(C, fx.y);
        }
    }
    return float4(0.0, 0.0, 0.0, 0.0);
}


//high cloud
float Density_h(const in float3 pos, const in float3 flowA, const in float3 flowB)
{
    float3
		pA = pos + flowA,
		pB = pos + flowB;
    
    float a = noise_p(pB / curvy_scale_h) * curvy_ang_h;
    
    float3 d = float3(cos(a), sin(a), 0.0) * curvy_strength_h;

    float
		densA = H_noise_densA * noise_p((pA + d) / H_scaleA),
		densB = H_noise_densB * noise_p((pB + d) / H_scaleB) * densA;

    return densA + densB;
}

float4 Cloud_high(const in float3 cam_dir, const in float3 cam_pos, const in float dist, const in float depth, float time, float height, float moonLight, float tf, float sunny)
{
    float distance = 0.0;
    float3 position = PosOnSphere(cam_pos, cam_dir, cam_pos.z + 1000000.0, height + 1000000.0, distance);

    if (distance > 0.0 && (depth == 1.0 || distance < dist) && cam_dir.z > -0.1)
    {
        float
			alpha = 0.0,
			noon_index = smoothstep(0.0, 0.3, tf),
			sunset_index = smoothstep(0.3, 0.1, tf) * smoothstep(-0.2, -0.1, tf) * sunny,
			suncross = dot(SunDirection.xyz, cam_dir),
			nearMoon = moonlight_strength * smoothstep(0.9, 1.2, dot(float3(-0.12, -0.9, 0.45), cam_dir)) * moonLight;
        
        float3
			c_dark = lerp(lerp(lerp(CBC_CN, CBC_CD, noon_index), lerp(CBC_N, CBC_D, noon_index), sunny), CBC_S, sunset_index),
			c_bright = lerp(lerp(lerp(CTC_CN, CTC_CD, noon_index), lerp(CTC_N, CTC_D, noon_index), sunny), CTC_S, sunset_index);
        
        c_bright += normalize(c_bright) * scatteringStrength * exp((suncross - 1.0) / scattering / 1.5) * 4.0;

        float3 C = float4(0.0, 0.0, 0.0, 0.0),
			flowA = -time * H_nA_move,
			flowB = -time * H_nB_move;

        alpha = Density_h(position / 1500.0, flowA, flowB);

		//density threshold
        alpha *= smoothstep(grow_h - softness_h, grow_h + softness_h, alpha);
        
        alpha *= smoothstep(-0.1, 0.1, cam_dir.z);
        
        C = lerp(c_bright, c_dark, alpha);

        return float4(C, alpha);
    }
    return float4(0.0, 0.0, 0.0, 0.0);
}

//It seems that sometimes the weather just suddenly changes, maybe I'll fix it someday.
float SunnyFactor()
{
    float4 c, w = WeatherAndTime;
    
    if (w.x == 0 || w.x == 1 || w.x == 2 || w.x == 6 || w.x == 11 || w.x == 13 || w.x == 17)
        c.x = 1.0;
    else
        c.x = 0.0;
    
    if (w.y == 0 || w.x == 1 || w.x == 2 || w.x == 6 || w.x == 11 || w.x == 13 || w.x == 17)
        c.y = 1.0;
    else
        c.y = 0.0;
    
    return lerp(c.x, c.y, w.z);
}

float4 PS_CLOUDWORK(VS_OUTPUT_POST IN, float2 vPos : VPOS) : COLOR
{
    float2 coord = IN.txcoord.xy;
    float depth = tex2D(SamplerDepth, coord.xy).x;
    float4
        r0 = tex2D(SamplerColor, coord.xy);
    
    //world pos calculation
    float4 tempvec;
    float4 worldpos;
    tempvec.xy = IN.txcoord.xy * 2.0 - 1.0;
    tempvec.y = -tempvec.y;
    tempvec.z = depth;
    tempvec.w = 1.0;
    worldpos.x = dot(tempvec, MatrixInverseVPRotation[0]);
    worldpos.y = dot(tempvec, MatrixInverseVPRotation[1]);
    worldpos.z = dot(tempvec, MatrixInverseVPRotation[2]);
    worldpos.w = dot(tempvec, MatrixInverseVPRotation[3]);
    worldpos.xyz /= worldpos.w;
    worldpos.w = 1.0;
    
    float
        ti = SunDirection.z,
        moon = 0.0,
        sunny = SunnyFactor(),
        dist = distance(float3(0, 0, 0), worldpos.xyz);
 
    float3 direction = normalize(worldpos.xyz);
    
    //clouds
    float4 highCloud = Cloud_high(direction, CameraPosition.xyz, dist, depth, Timer.x * speed, 2000.0, moon, ti, sunny);
    r0.xyz = lerp(r0.rgb, highCloud.rgb, highCloud.a);
    
    float4 midCloud = Cloud_mid(direction, CameraPosition.xyz, dist, depth, Timer.x * 500.0 * speed, moon, ti, sunny);
    r0.xyz = lerp(r0.rgb, midCloud.rgb, midCloud.a);
    
    return r0;
}

technique PostProcess
{
    pass P0
    {
        VertexShader = compile vs_3_0 VS_PostProcess();
        PixelShader = compile ps_3_0 PS_CLOUDWORK();
    }
}
