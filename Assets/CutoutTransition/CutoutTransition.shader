Shader "Custom/CutoutTransition"
{
	Properties
	{
		//[Enum(Off,0,Front,1,Back,2)] _CullMode ("Culling Mode", int) = 0
		_CutoffNormal ("_CutoffNormal", Range(0,1)) = 0.5
		_CutoffBlend ("_CutoffBlend", Range(0,1)) = 0.5
		_MainTex ("_MainTex (RGBA)", 2D) = "white" {}
		[NoScaleOffset] _MainTex2 ("_MainTex2 (RGBA)", 2D) = "white" {}
		_Progress ("_Progress", Range(0,1)) = 0
	}
	SubShader
	{
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		Cull Back Lighting Off ZWrite On

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
				fixed4 color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
			};

			sampler2D _MainTex;
			sampler2D _MainTex2;
			float4 _MainTex_ST;

			fixed _CutoffNormal;
			fixed _CutoffBlend;
			float _Progress;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
				return o;
			}

			#define PI 3.1415f
			
			fixed4 frag (v2f i) : SV_Target
			{
				//a curve that smoothly becomes highest at the middle of _Progress, i.e 0 -> 1 -> 0
				float factor = ( sin( ( 2*_Progress-0.5 )*PI )+1.0 ) * 0.5;

				//original
				float2 uv = i.uv;
				fixed4 c1 = tex2D (_MainTex, uv);
				fixed4 c2 = tex2D (_MainTex2, uv);
				fixed4 col = lerp(c1,c2,_Progress);

				//distortion
				float distortion = lerp( 0 , 1 , col.a * factor );
				uv = lerp ( uv , uv - (uv - 0.5) , distortion ); //image "scaled up" when distorted 

				//resample textures
				fixed4 col1 = tex2D (_MainTex, uv);
				fixed4 col2 = tex2D (_MainTex2, uv);
				col = lerp(col1,col2,_Progress);

				//cutoff
				float cutoff = lerp( _CutoffNormal , _CutoffBlend , factor ); 
				clip (col.a - cutoff);

				return col;
			}
			ENDCG
		}
	}
}
