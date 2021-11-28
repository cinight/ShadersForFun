Shader "RayMarching/DepthVolume"
{
	Properties
	{
		_Color ("Color",Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		//_AlphaStrength ("AlphaStrength", Range(0,3)) = 1
		//_Sharpness ("Sharpness", Range(0,10)) = 1
		_Size ("Size", Range(0,5)) = 1
		_NormalSampleSize ("NormalSampleSize", Range(1,5)) = 1
		_DepthStrength ("DepthStrength", Range(0,2)) = 1
		_DepthBase ("DepthBase", Range(-1,1)) = 0
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
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 wPos : TEXCOORD0;
				float eyeDepth : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_TexelSize; //texture pixel size
			float4 _MainTex_ST;
			//float _AlphaStrength;
			//float _Sharpness;
			float4 _Color;
			float _Size;
			float _NormalSampleSize;
			float _DepthStrength;
			float _DepthBase;
			
			#define STEPS 512

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				COMPUTE_EYEDEPTH(o.eyeDepth);
				return o;
			}

			#include "Lighting.cginc"
            float3 Diffuse (float3 worldNormal)
            {
                half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
                return nl * _LightColor0;
            }

			float4 Contrast(float4 col, float k) //k=1 is neutral, 0 to 2
			{
				float4 result = ((col - 0.5f) * max(k, 0)) + 0.5f;
				return result;
			}

			float GetDepth(float3 pos, float2 uvOffset)
			{
				float3 objSpace = mul(unity_WorldToObject, float4(pos, 1.0));

				//Mapping from front face
				float2 uvFront = objSpace.xy;
				uvFront *= _Size;
				uvFront += 0.5f;
				float depthFront = tex2D(_MainTex, uvFront + uvOffset).r;
				depthFront = Contrast(depthFront,_DepthStrength).r;
				depthFront += _DepthStrength*0.5 + _DepthBase;

				//Mapping from left face
				float2 uvLeft = objSpace.zy;
				uvLeft *= _Size;
				uvLeft += 0.5f;
				float depthLeft = tex2D(_MainTex, uvLeft + uvOffset).r;
				depthLeft = Contrast(depthLeft,_DepthStrength).r;
				depthLeft += _DepthStrength*0.5 + _DepthBase;

				return max(depthFront,depthLeft);
			}
			
			float4 frag (v2f i) : SV_Target
			{
				float4 result = _Color;
				result.a = 0;

				float3 wPos = i.wPos;
				float3 viewDir = normalize(wPos - _WorldSpaceCameraPos);
				float eyedepth = i.eyeDepth;

				for (int i = STEPS; i > 0; i--) //drawing start from back to front, this allows correct alpha blending
				{
					//Get fragment size in worldspace to determine step size, i.e. make rendering smooth
					//from https://forum.unity.com/threads/how-to-find-pixel-to-world-unit-ratio-per-fragment.496519/#post-3230082
                	float pixelToWorldScale = eyedepth * unity_CameraProjection._m11 / _ScreenParams.x;

					//current ray position (it moves along the view direction)
					float3 pos = wPos + ( viewDir * (float(i) * pixelToWorldScale));

					//Calculate UV and get depth
					//float2 uv = GetUV(pos);
					float depth = GetDepth(pos,0);

					//Calculate normal for lighting
					float2 uvN = float2(0,_MainTex_TexelSize.y*_NormalSampleSize);
					float depthN = GetDepth(pos,uvN);
					float2 uvE = float2(_MainTex_TexelSize.x*_NormalSampleSize,0);
					float depthE = GetDepth(pos,uvE);
					float2 uvS = float2(0,-_MainTex_TexelSize.y*_NormalSampleSize);
					float depthS = GetDepth(pos,uvS);
					float2 uvW = float2(-_MainTex_TexelSize.x*_NormalSampleSize,0);
					float depthW = GetDepth(pos,uvW);
					float3 posC = float3( 0 , 0 , depth ); //normalmap uses z as height
					float3 posN = float3( uvN , depthN );
					float3 posE = float3( uvE , depthE );
					float3 posS = float3( uvS , depthS );
					float3 posW = float3( uvW , depthW );
					float3 vecN = posN - posC;
					float3 vecE = posE - posC;
					float3 vecS = posS - posC;
					float3 vecW = posW - posC;
					float3 nor = ( cross(vecN, vecE) + cross(vecE, vecS) + cross(vecS, vecW) + cross(vecW, vecN) ) / 4;
					nor = -normalize( nor );
					nor = UnityObjectToWorldNormal(nor); //world normal

					//base shape according to mesh
					float3 _Centre = mul(unity_ObjectToWorld, float4(0.0, 0.0, 0.0, 1.0)).xyz;
					float dist = distance(pos,_Centre);

					//compare the distance, to decide whether it is within the "shape"
					//float addAlphaSMOOTH = smoothstep( depth , 0 , dist*2.0);
					float addAlpha = step( dist*2.0,depth);
					
					//Apply diffuse lighting to color and add alpha
					result.rgb = lerp(result.rgb,_Color*Diffuse(nor),min(addAlpha,0.5f));
					result.a += addAlpha;
				}
				
				//Fine tune alpha
				//result.a *= _AlphaStrength;
				//result.a = smoothstep(_Sharpness,10.0,result.a);
				result = saturate(result);

				return result;
			}
			ENDCG
		}
	}
}
