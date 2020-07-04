Shader "Custom/FacingImage"
{
	Properties
	{
		_Intensity("_Progress",Range(0,1)) = 1
		_MainTex ("Main Texture", 2D) = "white" {}
		_HeightTex ("Height", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
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
				float4 vertex : SV_POSITION;
				float2 screenPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _HeightTex;
			float _Intensity;
			float _MousePositionX;
			float _MousePositionY;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float2 uv = i.uv;
				float2 direction = i.screenPos - float2(_MousePositionX,_MousePositionY);

				float height = tex2D(_HeightTex, i.uv).r - 0.5f;

				uv += height * direction *_Intensity;
				fixed4 col = tex2D(_MainTex, uv);

				return col;
			}
			ENDCG
		}
	}
}
