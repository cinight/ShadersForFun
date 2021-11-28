Shader "RayMarching/VoronoiVolume"
{
	Properties
	{
		_Color ("Color",Color) = (1,1,1,1)
		_RimSize ("RimSize", Range(0,2)) = 1
		_AlphaStrength ("AlphaStrength", Range(0,3)) = 1
		_Sharpness ("Sharpness", Range(0,10)) = 1
		_TimeSpeed ("_TimeSpeed", Range(0,1)) = 1
	}
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Back Lighting Off ZWrite Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 wNor : NORMAL;
				float3 wPos : TEXCOORD0;
			};

			float _RimSize;
			float _AlphaStrength;
			float _Sharpness;
			float _TimeSpeed;
			float4 _Color;
			
			#define STEPS 64
			#define STEP_SIZE 0.02

            #define COUNT 20
            #define PI 3.1415926536

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.wNor = mul(unity_ObjectToWorld, v.normal);
				return o;
			}

            float3 random( float3 p ) 
            {
				float3 seed1 = float3(127.1,311.7,346.325);
				float3 seed2 = float3(269.5,183.3,735.523);
				float3 seed3 = float3(354.2,841.1,934.837);
                return frac( sin( float3( dot(p,seed1) , dot(p,seed2) , dot(p,seed3) ))*43758.5453 );
            }
			
			float4 frag (v2f i) : SV_Target
			{
				float4 result = _Color;
				result.a = 0;

				float3 wPos = i.wPos;
				float3 wNor= i.wNor;
				float3 viewDir = normalize(i.wPos - _WorldSpaceCameraPos);

				float3 pos = wPos;
				for (int i = 0; i < STEPS; i++)
				{
					//Voroni from https://thebookofshaders.com/12/
					float m_dist = 200.0; // for storing the minimun distance
					for (int j = 0; j < COUNT; j++)
					{
						//A random position
						float3 p = random(float(j)/float(COUNT));

						// Animate the point
						p = 0.5*sin(_Time.y*_TimeSpeed + 6.2831*p);

						//Convert to world space
						p = mul(unity_ObjectToWorld, float4(p,1.0)).xyz;

						// Keep the closer distance
						float dist = distance(pos,p);
						if(dist < m_dist)
						{
							m_dist = dist;
						}
					}

					//apply alpha
					result.a += m_dist;

					//next step
					pos += viewDir * STEP_SIZE;
				}
				
				//Apply rim
				float rim = pow(saturate(dot(-viewDir, wNor)),_RimSize);
				result.a *= rim;

				//Fine tune alpha
				result.a *= _AlphaStrength;
				result.a = smoothstep(_Sharpness,10.0,result.a);
				result.a = saturate(result.a);

				return result;
			}
			ENDCG
		}
	}
}
