//https://mortoray.com/2014/10/23/cubist-artwork-with-the-help-of-a-gpu/
Shader "Unlit/Shatter"
{
	Properties
	{
		_Progress("_Progress",Range(0,1)) = 1
		_MainTex ("Texture", 2D) = "white" {}

		[Header(Segment)]
		_Offset("_Offset",Range(-3,5)) = 1
		_Scale("_Scale",Range(0,10)) = 1
		_RotSpeed("_RotSpeed",Range(0,1)) = 1
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
			#pragma geometry GS
			#pragma target 5.0
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Offset;
			float _Scale;
			float _RotSpeed;
			float _Progress;

			float rand(float3 co)
			{
				return frac(sin(dot(co.xyz, float3(12.9898f, 78.233f, 45.5432f))) * 43758.5453f);
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = v.vertex;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = v.normal;

				return o;
			}

			void AddBlock(float3 at, inout float3 vertex)
			{
				float3 oVertex = vertex;

				float speed = rand(vertex.xyz) * _RotSpeed;
				float3 PosAngle;
				PosAngle.x = atan2(vertex.y, vertex.z);
				PosAngle.y = atan2(vertex.x, vertex.z);
				PosAngle.z = atan2(vertex.x, vertex.y);
				float3 PosRotation = PosAngle + _Time.w * speed;

				float PosLen = length(vertex.xyz);
				float3 PosOffset = cos(PosRotation) * sin(PosRotation) * PosLen;

				vertex.xyz = at + PosOffset*(rand(vertex.xyz))*_Scale*(1-_Progress);
				vertex = lerp(oVertex, vertex, _Progress);
			}

			[maxvertexcount(9)]
			void GS(triangle v2f i[3], inout TriangleStream<v2f> triangleStream)
			{
				v2f o;

				float4 vertex;
				float2 uv;
				float3 center = (i[0].vertex + i[1].vertex + i[2].vertex + 0.001f) /3.0f;
				float3 centerN = (i[0].normal + i[1].normal + i[2].normal + 0.001f) / 3.0f;
				float3 at = center + centerN * rand(center) * _Offset;
				int index = 0;

				index = 0;
				vertex = i[index].vertex;
				AddBlock(at, vertex.xyz);
				o.vertex = UnityObjectToClipPos(vertex);
				o.uv = i[index].uv;
				o.normal = i[index].normal;
				triangleStream.Append(o);

				index = 1;
				vertex = i[index].vertex;
				AddBlock(at, vertex.xyz);
				o.vertex = UnityObjectToClipPos(vertex);
				o.uv = i[index].uv;
				o.normal = i[index].normal;
				triangleStream.Append(o);

				index = 2;
				vertex = i[index].vertex;
				AddBlock(at, vertex.xyz);
				o.vertex = UnityObjectToClipPos(vertex);
				o.uv = i[index].uv;
				o.normal = i[index].normal;
				triangleStream.Append(o);
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				return col;
			}
			ENDCG
		}
	}
}
