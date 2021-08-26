/*===================================================================================
GTA SA - CloudWorks Alpha 4.0
by Brian Tu (RTU)

See my Github page for more information:
https://github.com/keroroxzz

2021/7/25

This is a volumetric cloud shader by RTU. It's currently bulky, 
I'd like to make the codes looks neat in the future.

License :　Creative Commons　Attribution-NonCommercial-ShareAlike 3.0 Unported
===================================================================================*/

#include "NoiseGenerator.hlsli"

//=================Time flow========================
float gameTime()
{
	float time = 0.0;
	
	//This is for the effect of time-lapse, which looks pretty cool in video.
#ifdef TIMELAPSE
    float3 axis_x = normalize(float3(0.85, -2.0, 0.45)),
    axis_z = cross(axis_x, float3(1.0, 0.0, 0.0)),
    axis_y = cross(axis_z, axis_x),
    
    yz = normalize(float3(0.0, dot(vSunLightDir.xyz, axis_y), dot(vSunLightDir.xyz, axis_z)));
    
    time -= atan2(yz.y, yz.z)*10000.0;
#endif

	time += CloudStartHeight*100.0f + CloudEndHeight;	//for controlling
	
	time += Time*CloudSpeed/100.0f;	//the time flow independent to the time of day

    return time;
}
static const float time = gameTime();

//=================Structs========================
struct CloudProfile
{
    float4 march;   //min length, max length, multiplicand, max step
    
    float2 cutoff;  // density cut, transparency cut

    float2 volumeBox;   //top, bottom
    float4 shape;       //top, mid, bot, thickness

    float brightness;
    float3 range;    //total, top, bottom
    float2 solidness;   //top, bottom
    
    float2 densityChunk;    //dens A,B
    
    float4 shadow;  //step length, detail strength, expanding, strength
    float4 distortion;  //max angle, strength, bump strength, small bump strength
    
    float fade;
    
    float3 densityDetail;   //dens C,D,E
    
    // 
    float3 scaleChunk;    //scale A,B, vertical stretch
    float3 scaleDetail;   //scale C,D,E
    float3 cloudShift;

    float3 offsetA;
    float3 offsetB;
    float3 offsetC;
    float3 offsetD;
};

struct CloudBaseColor
{
    float3 BaseColor;
    float3 BaseColor_Day;
    float3 BaseColor_Sunset;
};

//=================Cloud settings========================
static CloudProfile cloudProfiles[3]={
		
		//Bottom clouds
		{float4(5.0, 80.0, 8.0, 200.0),   //min length, max length, multiplicand, max step
        float2(0.0, 0.2),  // density cut, transparency cut
        float2(700.0, 300.0),   //top, bottom
        float4(700.0, 450.0, 0.0, 0.0),       //top, mid, bot, thickness
        0.5,
        float3(0.9 + CLOUD_COVERAGE[0]*0.16, 0.1, 0.2+CLOUD_COVERAGE[0]*0.4),    //total, top, bottom
        float2(5.0, 0.0) * CLOUD_COVERAGE[0],   //top, bottom
        float2(0.3, 0.5),    //dens A,B
        float4(60.0, 1.75, 0.1, 0.03),  //step length, detail strength, expanding, strength
        float4(1.6, 60.0, 8.0, 16.0),  //max angle, strength, bump strength, small bump strength
        6000.0,
        float3(0.3, 0.2, 0.6),   //dens C,D,E
        float3(0.0008, 0.005, 1.0),    //scale A,B, vertical stretch
        float3(0.02, 0.04, 0.1),   //scale C,D,E
        float3(-0.5, 0.0, 0.0),
        float3(1.8, -1.0, 0.0)*-time,
        float3(2.0, 0.2, 0.0)*-time,
        float3(3.0, 0.0, 0.5)*-time,
        float3(3.5, 0.0, -0.1)*-time},
		
		//Mid clouds
		{float4(12.0, 70.0, 8.0, 150.0),   //min length, max length, multiplicand, max step
		float2(0.0, 0.2),  // density cut, transparency cut
		float2(1900.0, 1500.0),   //top, bottom
		float4(2100.0, 1650.0, 0.0, 0.0),       //top, mid, bot, thickness
		0.5,
		float3(0.85+CLOUD_COVERAGE[1]*0.78, 0.0, 0.3+CLOUD_COVERAGE[1]*0.16),    //total, top, bottom
		float2(0.35, 0.1) * CLOUD_COVERAGE[1],   //top, bottom
		float2(0.25, 0.6),    //dens A,B
		float4(30.0, 1.0, 0.15, 0.1),  //step length, detail strength, expanding, strength
		float4(6.0, 50.0, 100.0, 50.0),  //max angle, strength, bump strength, small bump strength
		20000.0,
		float3(0.5, 0.25, 0.5),   //dens C,D,E
		float3(0.0008, 0.004, 1.5),    //scale A,B, vertical stretch
		float3(0.0142857, 0.0285714, 0.08),   //scale C,D,E
		float3(0.0, 0.0, 0.0),
		float3(1.5, -1.2, 0.0)*-time,
		float3(1.9, 0.5, 0.0)*-time,
		float3(2.5, 0.0, 0.5)*-time,
		float3(3.0, 0.1, -0.1)*-time},
		
		//High clouds
		{float4(5.0, 75.0, 500.0, 50.0),   //min length, max length, multiplicand, max step
		float2(0.0, 0.2),  // density cut, transparency cut
		float2(3600.0, 3500.0),   //top, bottom
		float4(3800.0, 3520.0, 3450.0, 0.0),       //top, mid, bot, thickness
		0.5,
		float3(1.0+CLOUD_COVERAGE[2]*0.9, 0.2, 0.35),    //total, top, bottom
		float2(0.25, 0.0),   //top, bottom
		float2(0.4, 0.3),    //dens A,B
		float4(50.0, 1.5, 0.02, 0.1),  //step length, detail strength, expanding, strength
		float4(2.5, 15000.0, 0.0, 0.0),  //max angle, strength, bump strength, small bump strength
		2000000.0,
		float3(0.2, 0.1, 0.6),   //dens C,D,E
		float3(0.00016, 0.0008, 1.5),    //scale A,B, vertical stretch
		float3(0.004, 0.006667, 0.02),   //scale C,D,E
		float3(0.0, 0.0, 0.0),
		float3(1.3, -1.8, 0.0)*-time,
		float3(1.6, 0.8, 0.0)*-time,
		float3(2.5, 0.2, 0.5)*-time,
		float3(3.0, 0.1, -0.1)*-time}};
		
static CloudBaseColor baseColor={
        float3(0.01, 0.015, 0.025),
        float3(0.27, 0.32, 0.4),
        float3(0.1647, 0.19608, 0.22745)};

//=================Functions=======================
inline float3 PosOnPlane(const in float3 origin, const in float3 direction, const in float h, inout float distance) {
    distance = (h - origin.z) / direction.z;
    return origin + direction * distance;
}

//generate parameters
float4 CloudShape(float z, float4 shape, float3 range) {
    float soft = map(z, shape.y, shape.x, range.z, range.y); //range of the soft part

    return float4(
        smoothstep(shape.z, lerp(shape.y, shape.z, shape.w), z) * smoothstep(shape.x, lerp(shape.y, shape.x, shape.w), z),    //shape factor
        range.x + soft,
        range.x - soft,
        soft);
}

inline float3 Distortion(float lump, float4 distortion)
{
    return float3(cos(lump*distortion.x)*distortion.y, 0.0, -lump*distortion.z);
}

//large chunk for the distribution of clouds.
float Chunk(in float3 pos, const in float2 density, const in float3 scale, const in float3 cloud_shift, const in float3 offsetA, const in float3 offsetB, in float cs) {

    pos.z /= scale.z;
    pos += cloud_shift * pos.z;
    
    float3
        pA = (pos + offsetA)*scale.x,
        pB = (pos + offsetB)*scale.y;
    
    float dens_a = noise3d(pA) * (noise3d(pB)*density.y + density.x) * cs;
    
    return dens_a;
}

//Detial noise for clouds
inline float DetailA(const in float3 pos, const in float3 density, const in float3 scale, const in float3 offsetC, const in float3 distortion) {

    return density.x * noise3d((pos + offsetC + distortion) * scale.x);
}

float DetailB(const in float lump_density, const in float3 pos, const in float3 density, const in float3 scale, const in float4 distortionParm, const in float3 offsetC, const in float3 offsetD, float cs) {

    float3 d = Distortion(lump_density, distortionParm);
    
    float3
        pD = pos + offsetD;

    float dens = DetailA(pos, density, scale, offsetC, d);
    
    d.z -= dens * distortionParm.w;

    dens += density.y * (noise3d((pD + d/3.0) * scale.y));
    dens += dens * density.z * noise3d((pD + d*8.0) * scale.z) ;

    return dens;
}

inline float DensityField(float lump, float detail)
{
    return lump*detail+lump;
}

inline float GetDensity(float density_field, float height, float low, float high, float2 volumeBox, float2 solidness)
{
    return clampMap(density_field, low, high, 0.0, clampMap(height, volumeBox.y, volumeBox.x, solidness.y, solidness.x));
}

inline float ShadowMarching(float dens, float3 p, float2 densityChunk, float3 densityDetail, float3 scaleChunk, float3 scaleDetail, float3 shift, float4 profile, float3 dens_thres, const in float3 offsetA, const in float3 offsetB, const in float3 offsetC, float3 SunDirection, float4 shadow, float2 volumeBox, float2 solidness, float4 distortionParm) {
    
    //exit for low density
    if(dens<=0.025) return dens*shadow.x;  //return a approx. value
    
    const float threshold = 2.0/shadow.w/shadow.x;
    
    float d = 0.0;
    float4 step = float4(SunDirection.xyz * shadow.x, shadow.x);
    
    //sampling
    for(int i=0; d<threshold && p.z<volumeBox.x && p.z>volumeBox.y && i<8; i++)
    {
        p += step.xyz;
        
        float4 cs = CloudShape(p.z, profile, dens_thres);
        float d1 = Chunk(p, densityChunk, scaleChunk, shift, offsetA, offsetB, cs.x);
        
        float3 displace = Distortion(d1, distortionParm);
        float d2 = DetailA(p, densityDetail, scaleDetail, offsetC, displace) * shadow.y;
        d += GetDensity(DensityField(d1, d2), p.z, cs.z-shadow.z, cs.y, volumeBox, solidness);
    }
    return d*shadow.w*step.w;
}

float4 CloudAtRay(CloudProfile a, CloudBaseColor b, const in float3 cam_dir, in float3 cam_pos, float3 light, float3 lightDirection, float time, in out float distance) {

    float4 d = float4(0.0, 0.0, 0.0, a.march.y); //distance, approx. distance, gap, the last march step
    
    float3 p = PosOnPlane(cam_pos, cam_dir, clamp(cam_pos.z, a.volumeBox.y+0.001, a.volumeBox.x-0.001), d.x);
    d.y = d.x;
	
    if (d.x >= 0.0 && distance>d.x) {
    
        a.range.x = 1.0f/a.range.x;
        
        float3 fx = float3(0.0, 0.0, 1.0); //brightness, cumulative density, transparency
        
        float last_sample = 0.0, pdf=0.0;
		
        //p += cam_dir * noise2d(cam_dir*500.0+float3(0.0,0.0,(int(Time*10.04548456)%100.0)))*a.march.x;
        
        for (int i = 0; fx.z > 0.0 && p.z <= a.volumeBox.x && p.z >= a.volumeBox.y && i < a.march.w && d.x - d.w < distance && d.x < a.fade; i++) {
            
            float3 
                cs = CloudShape(p.z, a.shape, a.range).xyz;

            float
                d1 = Chunk(p, a.densityChunk, a.scaleChunk, a.cloudShift, a.offsetA, a.offsetB, cs.x),
                d2 = DetailB(d1, p, a.densityDetail, a.scaleDetail, a.distortion, a.offsetC, a.offsetD, cs.x),
                df = DensityField(d1, d2);
                
            if(df>cs.z)
            {
                float
                    dens = GetDensity(df, p.z, cs.z, cs.y, a.volumeBox, a.solidness),
                    c_dens = (dens + last_sample) * a.march.x / 2.0f;
                    
                last_sample = dens;
                
                //fade into near objects
                if (d.x >= distance)
                    c_dens *= d.z / d.w;
                
                
                if(c_dens > 0.0f)
                    d.y = d.y * (1.0 - fx.z) + fx.z * d.x;
                    
                fx.y += c_dens;
                fx.z = (exp(-fx.y) - a.cutoff.y) / (1.0f - a.cutoff.y);
                d.z = distance - d.x;
                
                
                //lighting strength
                float dens_light=0.0;
                if(fx.y<2.3) 
                {
                    dens_light  = ShadowMarching(c_dens ,p, a.densityChunk, a.densityDetail, a.scaleChunk, a.scaleDetail, a.cloudShift, a.shape, a.range, a.offsetA, a.offsetB, a.offsetC, lightDirection, a.shadow, a.volumeBox, a.solidness, a.distortion); 
                    fx.x += c_dens * exp((-dens_light - fx.y));
                }  
            }
            
            //dynamic step length
            d.w = clampMap(2.0*df-pdf, cs.z*0.85, a.cutoff.x, a.march.x, a.march.y);
            d.w *= clampMap(d.x, 0.0, a.fade, 1.0, a.march.z);
            d.w += noise2d(p+Time)*a.march.x;
            pdf=df;
            
            //marching
            p += cam_dir * d.w;
            d.x += d.w;
        }
        
        if (fx.z < 1.0) {
            fx = saturate(fx);
            
            float suncross = dot(lightDirection, cam_dir);

            float3 z_pos = float3(0.0, 0.0, cam_pos.z);
            float3 sun_samp_pos = Game2Atm(z_pos + cam_dir*d.y);
            float3 my_cam_pos = Game2Atm(z_pos);

            float3
                c_bright = SunLight(light, sun_samp_pos, lightDirection, earth)*a.brightness;
            
            //Mie scattering

            float3 C = c_bright * fx.x*MiePhase(suncross) + b.BaseColor*(1.0-fx.z);
            C = atmosphere_scattering((1.0-fx.z), C, my_cam_pos, cam_dir, d.y/game2atm, lightDirection, earth);
            
            //calculate the depth for merging
            distance = distance*fx.z + d.y*(1.0-fx.z);
            
            return float4(C, fx.z);
        }
    }
    return float4(0.0, 0.0, 0.0, 1.0);
}

void CloudRandomness()
{
    for(int i=0;i<3;i++)
    {
		float3 rseed = float3(cloudProfiles[i].shape.x, cloudProfiles[i].volumeBox.y, time/2000.0);
        float rand_grow = noise3d(rseed);
		rand_grow *= 0.45;
		rand_grow += 0.65;
        cloudProfiles[i].range.x *= rand_grow*(1.0-CLOUD_COVERAGE[i])+CLOUD_COVERAGE[i];
    }
}

void CloudColorVarying(float3 SunDir, in out CloudBaseColor b)
{
    float 
        isNight = smoothstep(0.3, 0.1, SunDir.z),
        isDay = smoothstep(-0.03, 0.05, SunDir.z), 
        isSunSet = isNight*isDay;
        
    b.BaseColor += lerp(b.BaseColor_Day, b.BaseColor_Sunset, isSunSet)*isDay;
}

//Shadows cast by only one layer of clouds
float ShadowOnGround(CloudProfile a, float3 position, float3 SunDirection)
{    
    //Remember this you mtf
    a.range.x = 1.0f/a.range.x;
        
	float d;
    float3 samppos = PosOnPlane(position, SunDirection, a.shape.y, d);
	
    float d1 = 0.0, d2 = 0.0;
    float4 cs;
    
	cs = CloudShape(samppos.z, a.shape, a.range);
	d1 = Chunk(samppos, a.densityChunk, a.scaleChunk, a.cloudShift, a.offsetA, a.offsetB, cs.x);
	
	float3 displace = Distortion(d1, a.distortion);
	d2 = DetailA(samppos, a.densityDetail, a.scaleDetail, a.offsetC, displace) * a.shadow.y;
    
	float adjustTerm =  max(a.shape.y - max(a.volumeBox.y, position.z), 0.0) * clampMap(d, 0.0, 3000.0, 1.0, 0.0);
    
	return GetDensity(DensityField(d1, d2), samppos.z, cs.z-a.shadow.z*2.0f, cs.y*5.0f, a.volumeBox, a.solidness)*adjustTerm;
}

//Calculate the shadows from the two layers of clouds at the buttom
float CloudShadows(float3 WorldPos, float3 lightDir)
{
	float shadows=1.0;
	shadows *= exp(-ShadowOnGround(cloudProfiles[0], WorldPos, lightDir));
	shadows *= exp(-ShadowOnGround(cloudProfiles[1], WorldPos, lightDir));
	
	return shadows;
}

inline float GetCloudCoverage()
{
	return pow(saturate(max(CLOUD_COVERAGE[0], CLOUD_COVERAGE[1])+CLOUD_COVERAGE[2]*0.5f), 2.0);
}

float3 AdjustReflectedSky(float3 SkyColor, float3 worldpos)
{
	if(worldpos.z<cloudProfiles[1].volumeBox[1])
    {
        float saturation = (1.0-GetCloudCoverage()) + smoothstep( cloudProfiles[0].volumeBox[0], cloudProfiles[1].volumeBox[1], worldpos.z);
        saturation = saturate(saturation);
        SkyColor = saturation*SkyColor+(1.0-saturation)*length(SkyColor)*0.75f;
    }
	
	return SkyColor;
}

float4 RenderClouds(float3 ViewDir, float3 ViewPos, float3 sunDir, float distance)
{
    CloudRandomness();
    CloudColorVarying(sunDir, baseColor);
    
    float3 lightDir = 0.0;
    float3 light = LightSource(sunDir, lightDir);

    float4 cloud_temp = float4(0.0, 0.0, 0.0, 1.0);
        
    int i = (ViewPos.z>3500.0? 2:(ViewPos.z>1500.0? 1:0));
    float4 clouds = CloudAtRay(cloudProfiles[i], baseColor, ViewDir, ViewPos, light, lightDir, time, distance);
        
    i = (ViewPos.z>3500.0? 1:(ViewPos.z>1500.0? 0:1));
    cloud_temp = CloudAtRay(cloudProfiles[i], baseColor, ViewDir, ViewPos, light, lightDir, time, distance);
    clouds.rgb += cloud_temp.rgb*clouds.w;
    clouds.w = clouds.w*cloud_temp.w;
    
    i = (ViewPos.z>3500.0? 0:(ViewPos.z>1500.0? 2:2));
    cloud_temp = CloudAtRay(cloudProfiles[i], baseColor, ViewDir, ViewPos, light, lightDir, time, distance);
    clouds.rgb += cloud_temp.rgb*clouds.w;
    clouds.w = clouds.w*cloud_temp.w;
    
    return clouds;
}