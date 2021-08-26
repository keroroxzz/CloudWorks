/*===================================================================================
GTA SA - CloudWorks Alpha 4.0
by Brian Tu (RTU)

See my Github page for more information:
https://github.com/keroroxzz

2021/7/25

This is the AtmScattering shader from vanilla RenderHook, with the new sky added by
me, most of the sky calculations are replaced by the new one.

License :　Creative Commons　Attribution-NonCommercial-ShareAlike 3.0 Unported
===================================================================================*/

#include "NoiseGenerator.hlsli"

float3 pow3(float3 v, float n)
{
    return float3(pow(v.x, n), pow(v.y, n), pow(v.z, n));
}

static const float atmosphereStep = 15.0;
static const float lightStep = 3.0;
static const float fix=0.00001;

static const float3 sunLightStrength = 685.0*float3(1.0, 0.96, 0.949);
static const float moonReflecticity = 0.125;
static const float starStrength = 0.25;
static const float LightingDecay = 300.0;

static const float rayleighStrength = 1.85;
static const float rayleighDecay = 900.0;
static const float atmDensity = 3.0 + ATM_DENSE;
static const float atmCondensitivity = 1.0;

static const float3 waveLengthFactor = pow3(float3(6.5, 5.4, 4.5), 4.0);
static const float3 scatteringFactor = float3(1.0, 1.0, 1.0)*waveLengthFactor/rayleighDecay;   // for tuning, should be 1.0 physically, but you know.

static const float mieStrength = 0.125 + MIST*0.1;
static const float mieDecay = 100.0;
static const float fogDensity = 0.25 + MIST;

static const float earthRadius = 6.421;
static const float groundHeight = 6.371;
static const float3 AtmOrigin = float3(0.0, 0.0, groundHeight);

static const float4 earth = float4(0.0, 0.0, 0.0, earthRadius);

static const float game2atm = 1000000.0;


float3 Game2Atm(float3 gamepos)
{
    return gamepos/game2atm + AtmOrigin;
}

float3 Game2Atm_Alt(float3 gamepos)
{
    return float3(0.0, 0.0, gamepos.z/game2atm) + AtmOrigin;
}

float4 sphereCast(float3 origin, float3 ray, float4 sphere, float step, out float3 begin)
{
    float3 p = origin - sphere.xyz;
    
    float 
        r = length(p),
        d = length(cross(p, ray));    //nearest distance from view-ray to the center
        
    if (d > sphere.w+fix) return 0.0;    //early exit
        
    float
        sr = sqrt(sphere.w*sphere.w - d*d),    //radius of slicing circle
        dr = -dot(p, ray);    //distance from camera to the nearest point
        
    float3
        pc = origin + ray * dr,
        pf = pc + ray * sr,
        pb = pc - ray * sr;
    
    float sl; //stpe length
    
    if(r > sphere.w){
        
        begin = pb;
        sl = sr*2.0/step;
    }
    else{
    
        begin = origin;
        sl = length(pf - origin)/step;
    }
    return float4(ray * sl, sl);
}


float2 Density(float3 pos, float4 sphere, float strength, float condense)
{
    float r = groundHeight;
    float h = length(pos-sphere.xyz)-r;
    float ep = exp(-(sphere.w-r)*condense);
    
    float fog = fogDensity*(1.0/(1200.0*h+0.5)-0.04)/1.96;
    
    if(h<0.0)
        return float2(strength, fogDensity);

    return float2((exp(-h*condense)-ep)/(1.0-ep)*strength, fog);
}

float3 rayleighScattering(float c)
{
    return (1.0+c*c)*rayleighStrength/waveLengthFactor;
}

float MiePhase(float c)
{
    return 1.0f+1.6f*exp(20.0f*(c-1.0f));
}

float MieScattering(float c)
{
    return mieStrength*MiePhase(c);
}

float3 LightDecay(float densityR, float densityM)
{
    return float3(exp(-densityR/scatteringFactor - densityM*mieDecay));
}

float3 SunLight(float3 light, float3 position, float3 lightDirection, float4 sphere)
{
    float3 smp;
    float4 sms = sphereCast(position, lightDirection, sphere, lightStep, smp);
        
    float2 dl;
    
    for(float j=0.0; j<lightStep; j++)
    {
        smp+=sms.xyz/2.0;
        dl += Density(smp, sphere, atmDensity, atmCondensitivity)*sms.w;
        smp+=sms.xyz/2.0;
    }
    
    return light*LightDecay(dl.x, dl.y)/LightingDecay;
}

float3 LightSource(float3 SunDirection, out float3 SourceDir)
{
    if(SunDirection.z<-0.075)
    {
        SourceDir = -SunDirection;
        return sunLightStrength*moonReflecticity*smoothstep(-0.075, -0.105, SunDirection.z);
    }
    
    SourceDir = SunDirection;
    return sunLightStrength*smoothstep(-0.075, -0.025, SunDirection.z)*vSunColor.rgb;
}
  
float3 AtmosphereScattering(float3 background ,float3 marchPos, float4 marchStep, float3 ray, float3 lightStrength, float3 lightDirection, float strength, float4 sphere)
{
    float3 intensity=0.0;
    
    float ang_cos = dot(ray, lightDirection);
    float mie = MieScattering(ang_cos);
    float3 raylei = rayleighScattering(ang_cos);
    
    if(marchStep.w>0.015)
        marchStep /= marchStep.w/0.015;
    
    float2 dv=0.0;
    for(float i=0.0; i<atmosphereStep; i++)
    {
        float3 smp;
        float4 sms = sphereCast(marchPos, lightDirection, sphere, lightStep, smp);
        float2 sampling = Density(marchPos, sphere, atmDensity, atmCondensitivity)*marchStep.w;
            
        dv += sampling/2.0;
        
        float2 dl=dv;
        for(float j=0.0; j<lightStep; j++)
        {
            smp+=sms.xyz;
            dl += Density(smp, sphere, atmDensity, atmCondensitivity)*sms.w;
        }
        
        intensity += LightDecay(dl.x, dl.y)*(raylei*sampling.x + mie*sampling.y);
        
        dv += sampling/2.0;

        //marching
        marchPos+=marchStep.xyz;
    }
    
    return lightStrength*intensity*strength + background*LightDecay(dv.x, dv.y);
}

float3 ExponentialFog(float3 camera, float3 viewDir, float distance, in out float transparency)
{
    const float h0 = 0.0, 
        h1 = 160.0,
        a = 38.0,
        density = FOG_DENS/2000.0 + 0.00000001f;   //plus a small value to fix a weird problem

    float t, c1, e1, e2, e3, res;
    
    //fix horizontal error
    if(abs(viewDir.z)<=0.0001)
        viewDir.z=viewDir.z>0.0?0.0001:-0.0001;
    
    //Fix for altitude higher than h1
    if (camera.z>h1)
    {
        distance = max(0.0, distance + (camera.z - h1) / viewDir.z);
        camera.z = h1;
    }
    
    //ray length (inverse)
    t = max(1.0/distance, (viewDir.z>0.0) ? viewDir.z/(h1 - camera.z) : 0.0);
        
    //constants and values
    c1 = viewDir.z/a;
    e1 = exp((h0 - camera.z)/a);
    e2 = exp((h0 - camera.z - viewDir.z/t)/a);
    e3 = exp((h0 - h1)/a);
    
    //calculate the exp fog
    res = (e1 - e2)/c1 - e3/t;
    
    transparency = exp(-res*density);
    return (1.0f-transparency)*FOG_COLOR;
}

float3 atmosphere_scattering(float strength, float3 color, float3 camera, float3 ray, float distance, float3 SunDirection, float4 sphere)
{
    //fade-in and cut off
    if(distance<200.0)
        return color;
    float fade=smoothstep(200.0, 300.0, distance);
    
    //additionally multiply the distance since the map scale is too small to be scattered.
    float4 marchStep=0.0;
    marchStep.w = 15.0*distance/atmosphereStep/game2atm;
    marchStep.xyz = ray*marchStep.w;
    
    float3 lightDirection = 0.0;
    float3 lightStrength = LightSource(SunDirection, lightDirection);
    
    float3 scattered = AtmosphereScattering(color,  Game2Atm_Alt(camera), marchStep, ray, lightStrength, lightDirection, 1.0, sphere);
    return lerp(color, scattered, fade);
}

float3 WorldToSpace(float3 ray, float3 SunDirection)
{
    float3 
        axis_x = normalize(float3(0.85, -2.0, 0.45)),   //The rotation axis of the Earth
        axis_z = cross(axis_x, SunDirection),
        axis_y = cross(axis_z, axis_x);
        
    return normalize(float3(dot(axis_x, ray), dot(axis_y, ray), dot(axis_z, ray)));
}

float3 StarSky(float strength, float density, float curve, float3 ray)
{
    float3 star_ray = ray*density;
    
    float
        x = noise3d(star_ray + float3(250.1654, 161.15, 200.5556)),
        y = noise3d(star_ray + float3(12.04645, 20.012631, 300.4580)),
        z = noise3d(star_ray - float3(100.234, -20.0156, 3000.0912));
        
    star_ray = 2.0*float3(x, y, z)-1.0;
            
    return pow(saturate(dot(star_ray, ray)), curve)*strength*2.0f;
}

float3 OutterSpace(float3 ray, float3 SunDirection)
{
    float3 res=0.0;

    float ang_cos = dot(ray, SunDirection);
    
    //The sun
    if(ang_cos>0.9999){
        res += 0.1*sunLightStrength*smoothstep(0.9999,0.99995,ang_cos);
    }
        
    //The moon
    else if(ang_cos<-0.99978){
        res += 0.03*moonReflecticity*sunLightStrength*smoothstep(-0.99978,-0.99985,ang_cos);
    }
    
    //Stars
    else{
        res += StarSky(starStrength, 300.0, 6.0, WorldToSpace(ray, SunDirection))*smoothstep(0.05, -0.1, SunDirection.z);
    }
    
    return res;
}

//The blue hour is hard to be made by ray marching atm.
float3 BlueHour(float3 sunDirection, float3 ray, float3 camera)
{
    float strength = smoothstep(0.1, 0.0,  sunDirection.z) * smoothstep(-0.25, 0.0,  sunDirection.z);
    strength *= (pow((ray.z+1.0)/2.0, 3.0)*0.5 + 0.25*dot(ray, sunDirection) + 0.75);
	strength *=	saturate(1.0-camera.z/10000.0);
	strength *=	smoothstep(-0.5, 0.0,  ray.z);
    
    return float3(0.07, 0.12, 0.16)*saturate(strength);
}

float3 Sky(float3 background, float3 camera, float3 ray, float3 SunDirection, float4 sphere)
{
    float3 marchPos;
    float4 marchStep = sphereCast(camera, ray, sphere, atmosphereStep, marchPos);
    
    if (marchStep.w == 0.0) return background;
    
    float strength=1.0;
    float3 ground;
    if(sphereCast(camera, ray, float4(0.0, 0.0, 0.0, groundHeight-0.00075), atmosphereStep, ground).w>0.0)
    {
        if(length(ground-marchPos)>0.0 && dot(ground-marchPos, ray)>0.0)
        {
            marchStep.xyz = (ground-marchPos)/atmosphereStep;
            marchStep.w = length(marchStep.xyz);
            background=0.0;
        }
    }
    
    float3 lightDirection = 0.0;
    float3 lightStrength = LightSource(SunDirection, lightDirection);
    
    float3 blueFix = BlueHour(SunDirection, ray, camera);
    
    return AtmosphereScattering(background, marchPos, marchStep, ray, lightStrength, lightDirection, strength, sphere) + blueFix;
}