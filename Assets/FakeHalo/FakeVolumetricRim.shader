Shader "Custom/FakeConeLight" 
{
Properties 
{
	_MainTex ("MainTex", 2D) = "white" {}
	_Rim ("Rim", Range(0,1.5)) = 1
	_Brightness("Brightness", Range(1,50)) = 1
	[HDR] _Color ("Color",Color) = (1,1,1,1)
}

Category {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	Blend SrcAlpha One
	//Blend SrcAlpha OneMinusSrcAlpha
	Cull Back ZWrite Off Lighting Off
	
	SubShader {
		Pass {
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			fixed _Rim;
			
			struct appdata_t 
			{
				float4 vertex : POSITION;
				//fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				float4 normal : NORMAL;
			};

			struct v2f 
			{
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				//float4 pos : TEXCOORD1;
				//float4 normal : NORMAL;
			};
			
			float4 _MainTex_ST;
			float4 _Color;
			float _Brightness;

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				
				float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
				float dotProduct = dot(v.normal, viewDir);
				o.color = smoothstep(1 - _Rim, 1.0, dotProduct) *_Color;

				o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 tex = tex2D(_MainTex, i.texcoord)*i.color;
				float dist = length(i.texcoord - 0.5f)*2.25f;
				dist = pow(dist, 0.2f);
				dist = 1 - dist;
				float factor = lerp(1, _Brightness,dist);
				tex.a *= factor;
				return tex;
			}
			ENDCG 
		}
	}	
}
}
