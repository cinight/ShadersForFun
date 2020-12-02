Shader "ParallaxEffect"
{
	Properties
	{
		_Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5
		_MainTex ("_MainTex (RGBA)", 2D) = "white" {}
		_Thickness ("_Thickness", Range(0,0.5)) = 0.1
		[IntRange] _Layers ("_Layers", Range(1,50)) = 10
		_Specular ("_Specular", Range(1,10)) = 1
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
			#include "UnityLightingCommon.cginc"
			#include "UnityStandardBRDF.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float3 wview : TEXCOORD1;
				float3 wnor : NORMAL;
				float4 vertex : SV_POSITION;
				float4 color : COLOR;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Cutoff;
			float _Thickness;
			int _Layers;
			float _Specular;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;

				//Parallax https://catlikecoding.com/unity/tutorials/rendering/part-20/
				float3x3 objectToTangent = float3x3
				(
					v.tangent.xyz,
					cross(v.normal, v.tangent.xyz) * v.tangent.w,
					v.normal
				);
				float3 tangentViewDir = mul(objectToTangent, ObjSpaceViewDir(v.vertex));
				tangentViewDir = normalize(tangentViewDir);
				o.uv.zw = tangentViewDir.xy / (tangentViewDir.z + 0.42);

				//For lighting
				o.wview = WorldSpaceViewDir(v.vertex);
				o.wnor = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0.0)).xyz);

				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.uv.xy);
				float4 ocol = col;

				//thickness
				float step = _Thickness / float(_Layers);
				for(int k=_Layers; k>0; k--)
				{
					//thickness layer color
					float2 uvT = i.uv.xy - i.uv.zw * step * (float)(k);
					float4 colT = tex2D(_MainTex, uvT);
					col.rgb = colT.rgb;
					col.a += colT.a;
				}

				//combine colors
				col.rgb = lerp(col.rgb,ocol.rgb,ocol.a);
				col.a = saturate(col.a);
				clip (col.a - _Cutoff);

				//world normals
				float3 norT = normalize(i.wview); //the normal of the thickness layers
				float3 nor = lerp( norT , i.wnor , ocol.a );

				//diffuse + ambient
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float atten = max(0.0,dot(nor, lightDir));
				col.rgb *= atten * _LightColor0 + ShadeSH9(half4(nor,1));

				//specular https://catlikecoding.com/unity/tutorials/rendering/part-4/
				float3 halfVector = normalize(lightDir + i.wview);
				float3 specular = _LightColor0 * pow( DotClamped( halfVector, nor) , _Specular * 100 );
				col.rgb += specular;

				return col;
			}
			ENDCG
		}
	}
}
