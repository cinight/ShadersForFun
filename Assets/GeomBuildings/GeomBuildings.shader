Shader "Custom/GeomBuildings"
{
	Properties
	{
		//_GroundColor("_GroundColor",Color) = (0.4,1,0.4,1)
		_Height("_Height",Range(0,3)) = 1
		_Width("_Width",Range(0,1)) = 1
		_MainTex ("_MainTex (RGBA)", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Cull Back

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float4 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2g
			{
				float4 vertex : SV_POSITION;
				float4 normal : NORMAL;
				float4 color : COLOR;
				float4 texcoord : TEXCOORD0;
			};

			struct g2f
			{
				float4 vertex : SV_POSITION;
				float4 normal : NORMAL;
				float4 color : COLOR;
				float4 texcoord : TEXCOORD0;
			};

			//float4 _GroundColor;
			float _Height, _Width;
			sampler2D _MainTex;
			
			float random(float2 seed)
			{
				return frac(sin(dot(seed, float2(12.9898f, 78.233f))) * 43758.5453f);
			}

			v2g vert (appdata v)
			{
				v2g o;

				o.vertex = v.vertex;
				o.normal = v.normal;
				o.texcoord = v.texcoord;
				o.color = 0;

				////////////////////
				//       3  / 1 
				//       0 /  2

				return o;
			}

			float2 CalculateUV(float2 pos)
			{
				float2 uv = 0;

				return uv;
			}

			[maxvertexcount(15)] // 3 * 5 triangles
			void geom(triangle v2g i[3], inout TriangleStream<g2f> triangleStream)
			{
				g2f o;

				float4 v0 = i[0].vertex;
				float4 v1 = i[1].vertex;
				float4 v2 = i[2].vertex;

				int longestLengthid = -1;
				float d0 = length (v0.xz -v1.xz);
				float d1 = length (v1.xz -v2.xz);
				float d2 = length (v2.xz -v0.xz);
				
				float4 vC = 0;

				//Get longest length
				if(d0 > d1 && d0 > d2)
				{
					vC = (v0 + v1) / 2;
					longestLengthid = 0;
				}
				else if (d1 > d0 && d1 > d2)
				{
					vC = (v1 + v2) / 2;
					longestLengthid = 1;
				}
				else
				{
					vC = (v2 + v0) / 2;
					longestLengthid = 2;
				}
				
				//Random width
				float w = _Width * random(vC.xz* 345324.324f);
				v0 -= w * (v0 - vC);
				v1 -= w * (v1 - vC);
				v2 -= w * (v2 - vC);

				//Lid =======================================================

				float h = _Height * random(i[0].vertex.xz* 345324.324f);

				float4 lid0 = v0 +  i[0].normal * h;
				o.color = i[0].color;
				o.vertex = UnityObjectToClipPos(lid0);
				o.normal = i[0].normal;
				o.texcoord.x = step(v1.x,v0.x) * step(v2.x,v0.x);
				o.texcoord.y = step(v1.y,v0.y) * step(v2.y,v0.y);
				o.texcoord.zw = 0;
				triangleStream.Append(o);

				float4 lid1 = v1 + i[1].normal * h;
				o.color = i[0].color;
				o.vertex = UnityObjectToClipPos(lid1);
				o.normal = i[1].normal;
				o.texcoord.x = step(v0.x,v1.x) * step(v2.x,v1.x);
				o.texcoord.y = step(v0.y,v1.y) * step(v2.y,v1.y);
				o.texcoord.zw = 0;
				triangleStream.Append(o);

				float4 lid2 = v2 + i[2].normal * h;
				o.color = i[0].color;
				o.vertex = UnityObjectToClipPos(lid2);
				o.normal = i[2].normal;
				o.texcoord.x = step(v0.x,v2.x) * step(v1.x,v2.x);
				o.texcoord.y = step(v0.y,v2.y) * step(v1.y,v2.y);
				o.texcoord.zw = 0;
				triangleStream.Append(o);

				triangleStream.RestartStrip();

				//Side - 2 & 0 = id 2 ======================================================
				if(longestLengthid != 2)
				{
					//o.color = _GroundColor;

					o.vertex = UnityObjectToClipPos(v2);
					o.normal = i[2].normal;
					o.texcoord = float4(1,0,0,0);
					triangleStream.Append(o);

					o.vertex = UnityObjectToClipPos(v0);
					o.normal = i[0].normal;
					o.texcoord = float4(0,0,0,0);
					triangleStream.Append(o);

					o.vertex = UnityObjectToClipPos(lid2);
					o.normal = i[2].normal;
					o.texcoord = float4(1,1,0,0);
					triangleStream.Append(o);
					
					o.vertex = UnityObjectToClipPos(lid0);
					o.normal = i[0].normal;
					o.texcoord = float4(0,1,0,0);
					triangleStream.Append(o);

					triangleStream.RestartStrip();
				}

				//Side - 1 & 2 = id 1 =======================================================
				if(longestLengthid != 1)
				{
					o.vertex = UnityObjectToClipPos(v1);
					o.normal = i[1].normal;
					o.texcoord = float4(1,0,0,0);
					triangleStream.Append(o);

					o.vertex = UnityObjectToClipPos(v2);
					o.normal = i[2].normal;
					o.texcoord = float4(0,0,0,0);
					triangleStream.Append(o);

					o.vertex = UnityObjectToClipPos(lid1);
					o.normal = i[1].normal;
					o.texcoord = float4(1,1,0,0);
					triangleStream.Append(o);
					
					o.vertex = UnityObjectToClipPos(lid2);
					o.normal = i[2].normal;
					o.texcoord = float4(0,1,0,0);
					triangleStream.Append(o);

					triangleStream.RestartStrip();
				}

				//Side - 0 & 1 = id 0 =======================================================

				if(longestLengthid != 0)
				{
					o.vertex = UnityObjectToClipPos(v0);
					o.normal = i[0].normal;
					o.texcoord = float4(1,0,0,0);
					triangleStream.Append(o);

					o.vertex = UnityObjectToClipPos(v1);
					o.normal = i[1].normal;
					o.texcoord = float4(0,0,0,0);
					triangleStream.Append(o);

					o.vertex = UnityObjectToClipPos(lid0);
					o.normal = i[0].normal;
					o.texcoord = float4(1,1,0,0);
					triangleStream.Append(o);
					
					o.vertex = UnityObjectToClipPos(lid1);
					o.normal = i[1].normal;
					o.texcoord = float4(0,1,0,0);
					triangleStream.Append(o);

					triangleStream.RestartStrip();
				}
			}

			fixed4 frag (g2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex,i.texcoord); //* i.color;

				return col;
			}
			ENDCG
		}
	}
}
