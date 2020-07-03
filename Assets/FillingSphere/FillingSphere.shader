Shader "Custom/FillingSphere" 
{
	Properties 
	{
		_MaskPos ("Mask Position", Range(0,1)) = 1
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_LidTex ("Lid (RGB)", 2D) = "white" {}
		_Ramp ("Ramp (RGB)", 2D) = "white" {}
		_RimColor ("Rim Color", Color) = (0.26,0.19,0.16,0.0)
		_RimThickness ("Rim Thickness", Range(0.0,1.0)) = 1.0
      	_RimPower ("Rim Power", Range(1.0,50.0)) = 3.0
	}
	SubShader 
	{
		Tags { "RenderType"="Opaque" }
		LOD 200
		cull Back ZWrite On
		
		CGPROGRAM
		#pragma surface surf Ramp fullforwardshadows vertex:vert
		#pragma target 4.0

		sampler2D _MainTex;
		sampler2D _LidTex;
		sampler2D _Ramp;

		float _MaskPos;
		float4 _RimColor;
      	float _RimPower;
		float _RimThickness;

		float4 LightingRamp (SurfaceOutput s, float3 lightDir, float atten) 
		{
	        float NdotL = dot (s.Normal, lightDir);
	        float diff = NdotL * 0.5 + 0.5;
	        float3 ramp = tex2D (_Ramp, float2(diff,0)).rgb;
	        float4 c;
	        c.rgb = s.Albedo + _LightColor0.rgb * ramp;
			c.rgb *= atten;
	        c.a = s.Alpha;
	        return c;
    	}

		struct Input 
		{
			float2 uv_LidTex;
			float2 uv_MainTex;
			float4 color;
			float3 viewDir;
			float isLid;
		};

		float2 scaleCircular(float2 pos, float y , float level, float isLid)
		{
			const float PI = 3.1415f;
			float radius = 0.5f;
			float2 radiusY = sqrt( radius*radius - y*y ); //radius based on Y
			float2 radiusL = sqrt( radius*radius - level*level ); //radius based on level

			float angle = frac(atan2(pos.x,pos.y)/PI*0.5f); //0 to 1
			angle *= 360.0f;
			angle = radians(angle);

			//position along radius
			float2 newPos = pos;
			newPos.x = radiusL * sin(angle);
			newPos.y = radiusL * cos(angle);

			//prevent hole at bottom
			if(y == -0.5f) newPos = pos;

			//Keep position of upperhalf at levelhalf
			float upperHalf = step(0,y);
			float levelUpperHalf = step(0,level);
			newPos = lerp(newPos,pos,upperHalf*levelUpperHalf);

			//Scale down lid when lowerhalf
			newPos = lerp(newPos,newPos*(radiusY/radius),upperHalf*1-levelUpperHalf);
			
			return lerp( pos , newPos , isLid );
		}

        float3 Contrast(float3 col, float k) //k=1 is neutral, 0 to 2
        {
            return ((col - 0.5f) * max(k, 0)) + 0.5f;
        }

		void vert (inout appdata_full v, out Input o) 
       	{
			UNITY_INITIALIZE_OUTPUT(Input,o);

			float center = 0.5f;
			float level = _MaskPos-center;

			//0=body, 1=lid
			float isLid = step(level, v.vertex.y);

			//position according to level radius
			v.vertex.xz = scaleCircular(v.vertex.xz,v.vertex.y,level,isLid);

			//Clamp the level
			v.vertex.y = lerp(v.vertex.y,level,isLid);

			//New vertex normal
			v.normal = lerp(v.normal,float3(0,1,0),isLid);

			//Debug color 0=body, 1=lid
			o.color = lerp(float4(1,0,0,1),float4(0,0,1,1),isLid);

			//output
			o.isLid = isLid;
		}

		void surf (Input IN, inout SurfaceOutput o) 
		{
			float4 c = tex2D (_MainTex, IN.uv_MainTex);
			float4 l = tex2D (_LidTex, IN.uv_LidTex);
			o.Albedo = lerp(c.rgb,l.rgb,IN.isLid);
			
			float rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));
			rim = Contrast(rim*_RimThickness, _RimPower);
			rim = saturate(rim);
          	o.Emission = _RimColor.rgb * rim;

			o.Alpha = 1;
		}
		ENDCG

	}
	FallBack "Diffuse"
}
