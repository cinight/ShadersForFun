//Only directional light
Shader "Unlit/ShadowColor"
{
	Properties
	{
		_MainTex ("_MainTex (RGBA)", 2D) = "white" {}
		_Color("Main Color", Color) = (1,1,1,1)
		_ShadowColor("Shadow Color", Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }

		Pass
		{
			Tags {"LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float4 _ShadowCoord : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
			float4 _ShadowColor;
			sampler2D _ShadowMapTexture;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				o._ShadowCoord = ComputeScreenPos(o.pos);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				col *= _Color;

				float attenuation = tex2Dproj(_ShadowMapTexture, i._ShadowCoord).r;
				float4 shadow = lerp( _ShadowColor , 1, attenuation);
				
				col *= shadow;

				return col;
			}
			ENDCG
		}
		//========================================================================================
        Pass
     	{
			Name "ShadowCaster"
			Tags{ "Queue" = "Transparent" "LightMode" = "ShadowCaster"  }

         	CGPROGRAM
 			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#pragma fragmentoption ARB_precision_hint_fastest
 
			#include "UnityCG.cginc"
 
			struct v2f
			{
				float4 pos : SV_POSITION;
			};
 
			v2f vert(appdata_base v)
			{
				v2f o;

				float4 wPos = mul(unity_ObjectToWorld, v.vertex);
				float3 wNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));

					float3 wLight = normalize(_WorldSpaceLightPos0.xyz);

					float shadowCos = dot(wNormal, wLight);
					float shadowSine = sqrt(1-shadowCos*shadowCos);
					float normalBias = unity_LightShadowBias.z * shadowSine;

					wPos.xyz -= wNormal * normalBias;

				o.pos = mul(UNITY_MATRIX_VP, wPos);
				o.pos = UnityApplyLinearShadowBias(o.pos);

				return o;
			}
 
			float4 frag(v2f i) : COLOR
			{
				return 0;
			}
 
         	ENDCG
    	}
	}
}
