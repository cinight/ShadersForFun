Shader "Unlit/WaterDrop"
{
	Properties
	{
		[Enum(Off,0,Front,1,Back,2)] _CullMode ("Culling Mode", int) = 0
		[HDR] _Color ("Color",Color) = (1,1,1,1)
		_DropTex ("R:Drop G:Stretch B:Distort", 2D) = "white" {}
		_Progress ("Progress", Range(0,1)) = 0
		_Distortion ("_Distortion", Range(0,2)) = 0
		_TrailDistortion ("_TrailDistortion", Range(0,20)) = 0
		_SmoothStep ("_SmoothStep", Range(0,1)) = 0
		_TrailLength1 ("_TrailLength1", Range(-20,20)) = 0
		_TrailLength2 ("_TrailLength2", Range(-20,20)) = 0
	}
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha //Alpha Blend
		//Blend SrcAlpha One //Additive
		//Blend SrcAlpha One BlendOp RevSub //Multiply c.rgb = 1-c.rgb;
		//Blend OneMinusDstColor OneMinusSrcAlpha //Invert c *= c.a;
		//Blend One OneMinusSrcAlpha //Additive + Alpha Blend c *= c.a;

		Cull [_CullMode] Lighting Off ZWrite Off

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
			};

			float4 _Color;
			sampler2D _DropTex;
			float4 _DropTex_ST;
			float _Progress;
			float _TrailLength1,_TrailLength2;
			fixed _Distortion;
			fixed _TrailDistortion;
			fixed _SmoothStep;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 col = tex2D(_DropTex, i.uv);

				//The scaled UV scroll down according to progress
				fixed2 nuv = i.uv;
				//X
				nuv.x -= 0.5f;
				nuv *= _DropTex_ST.xy;
				nuv.x += 0.5f;
				nuv.x += _DropTex_ST.z;
				//Y
				nuv.y = lerp(nuv.y+1,nuv.y-1,_Progress);

				//TrailStretch
				float trailStretch = tex2D(_DropTex, nuv).g;
				float stretch = lerp(_TrailLength2,_TrailLength1,_Progress);
				nuv.y += trailStretch*stretch;
				
				//UV distortion to drop
				fixed dist = i.uv.x-0.5f;
				nuv += col.b  * _Distortion * (1+trailStretch*_TrailDistortion);
				
				//Final Color
				float4 result = float4(1,1,1,tex2D(_DropTex, nuv).r);
				result.rgb = _Color.rgb;

				//Also fade out according to length
				result.a = smoothstep(result.a,0,_SmoothStep);
				result.a *= _Color.a;

				return result;
			}
			ENDCG
		}
	}
}
