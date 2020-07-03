Shader "Custom/GeomBuildingsTess"
{
	Properties
	{
		_GroundColor("_RootColor",Color) = (0.4,1,0.4,1)
		_Height("_Height",Range(0,3)) = 1
		_Width("_Width",Range(0,1)) = 1
		_MainTex ("_MainTex (RGBA)", 2D) = "white" {}
		[IntRange] _TessEdge ("Tessellation", Range(1,40)) = 1
		//_TessEdg2("Edge Tess2", Vector) = (1,1,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "DisableBatching" ="True" }
		Cull Back

		Pass
		{
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom
			#pragma hull HS
    		#pragma domain DS
			
			#include "UnityCG.cginc"
			#include "UnityStandardBRDF.cginc"

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

    		struct HS_ConstantOut
    		{
       			float TessFactor[4]    : SV_TessFactor;
        		float InsideTessFactor[2] : SV_InsideTessFactor;
    		};

			struct g2f
			{
				float4 vertex : SV_POSITION;
				float4 normal : NORMAL;
				float4 color : COLOR;
				float4 texcoord : TEXCOORD0;
			};

			float4 _GroundColor;
			float _Height, _Width;
			sampler2D _MainTex;
			int _TessEdge;
			//float4 _TessEdge2;
			
			float random(float3 seed)
			{
				return frac(sin(dot(seed, float3(12.9898f, 78.233f, 65.68f))) * 43758.5453f);
			}

			float4 calculateNormal(float4 p0, float4 p1, float4 p2)
			{
				float3 nor = normalize(cross(p2.xyz - p1.xyz, p0.xyz - p1.xyz));
				return float4(nor, 1);
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

    		HS_ConstantOut HSConstant( InputPatch<v2g, 4> i )
    		{
        		HS_ConstantOut o = (HS_ConstantOut)0;
        		o.TessFactor[0] = o.TessFactor[1] = o.TessFactor[2] = o.TessFactor[3] = _TessEdge.x;
        		o.InsideTessFactor[0] = o.InsideTessFactor[1] = _TessEdge.x;
        		return o;
    		}

    		[domain("quad")]
    		[partitioning("integer")]
    		[outputtopology("triangle_cw")]
    		[patchconstantfunc("HSConstant")]
    		[outputcontrolpoints(4)]
    		v2g HS( InputPatch<v2g, 4> i, 
				uint uCPID : SV_OutputControlPointID )
    		{
        		v2g o = (v2g)0;
        		o.vertex = i[uCPID].vertex;
				o.normal = i[uCPID].normal;
				o.color = i[uCPID].color;
				o.texcoord = i[uCPID].texcoord;
        		return o;
    		}
    
    		[domain("quad")]
    		v2g DS( HS_ConstantOut HSConstantData, 
    					const OutputPatch<v2g, 4> i, 
    					float2 BarycentricCoords : SV_DomainLocation)
    		{
        		v2g o = (v2g)0;
     
        		float fU = BarycentricCoords.x;
        		float fV = BarycentricCoords.y;
        		//float fW = BarycentricCoords.z;

				float3 nor1 = lerp(i[0].normal, i[1].normal, fU);
				float3 nor2 = lerp(i[3].normal, i[2].normal, fU);
				float3 nor = lerp(nor1, nor2, fV);
				o.normal = float4(nor, 0.0);

				float4 ver1 = lerp(i[0].vertex, i[1].vertex, fU);
				float4 ver2 = lerp(i[3].vertex, i[2].vertex, fU);
				float4 ver = lerp(ver1, ver2, fV);
        		o.vertex = ver;

				float4 col1 = lerp(i[0].color, i[1].color, fU);
				float4 col2 = lerp(i[3].color, i[2].color, fU);
				float4 col = lerp(col1, col2, fV);
        		o.color = col;

				float4 tex1 = lerp(i[0].texcoord, i[1].texcoord, fU);
				float4 tex2 = lerp(i[3].texcoord, i[2].texcoord, fU);
				float4 tex = lerp(tex1, tex2, fV);
        		o.texcoord = tex;
           
        		return o;
    		}

			[maxvertexcount(15)] // 3 * 5 triangles
			void geom(triangle v2g i[3], inout TriangleStream<g2f> triangleStream)
			{
				g2f o;

				float4 v0 = i[0].vertex;
				float4 v1 = i[1].vertex;
				float4 v2 = i[2].vertex;

				int longestLengthid = -1;
				float d0 = length (v0 -v1);
				float d1 = length (v1 -v2);
				float d2 = length (v2 -v0);
				
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
				float w = _Width * random(vC * 345324.324f);
				v0 -= w * (v0 - vC);
				v1 -= w * (v1 - vC);
				v2 -= w * (v2 - vC);

				//Normal of this triangle
				float4 vN = i[longestLengthid].normal;
			

				//Lid =======================================================
				float4 color = 1;
				float4 h = _Height * random( vC * 685215.25f ) * vN;
				float4 nor = calculateNormal(v0, v2, v1);

				float4 lid0 = v0;
				lid0 += h;
				o.color = color;
				o.vertex = UnityObjectToClipPos(lid0);
				o.normal = nor;
				o.texcoord.x = step(v1.x,v0.x) * step(v2.x,v0.x);
				o.texcoord.y = step(v1.y,v0.y) * step(v2.y,v0.y);
				o.texcoord.zw = 0;
				triangleStream.Append(o);

				float4 lid1 = v1;
				lid1 += h;
				o.color = color;
				o.vertex = UnityObjectToClipPos(lid1);
				o.normal = nor;
				o.texcoord.x = step(v0.x,v1.x) * step(v2.x,v1.x);
				o.texcoord.y = step(v0.y,v1.y) * step(v2.y,v1.y);
				o.texcoord.zw = 0;
				triangleStream.Append(o);

				float4 lid2 = v2;
				lid2 += h;
				o.color = color;
				o.vertex = UnityObjectToClipPos(lid2);
				o.normal = nor;
				o.texcoord.x = step(v0.x,v2.x) * step(v1.x,v2.x);
				o.texcoord.y = step(v0.y,v2.y) * step(v1.y,v2.y);
				o.texcoord.zw = 0;
				triangleStream.Append(o);

				triangleStream.RestartStrip();

				//Side - 2 & 0 = id 2 ======================================================
				
				if(longestLengthid != 2)
				{
					nor = calculateNormal(lid2, v0,v2 );

					o.vertex = UnityObjectToClipPos(v2);
					o.normal = nor;
					o.color = _GroundColor;
					o.texcoord = float4(1,0,0,0);
					triangleStream.Append(o);

					o.vertex = UnityObjectToClipPos(v0);
					o.normal = nor;
					o.color = _GroundColor;
					o.texcoord = float4(0,0,0,0);
					triangleStream.Append(o);

					o.vertex = UnityObjectToClipPos(lid2);
					o.normal = nor;
					o.color = 1;
					o.texcoord = float4(1,1,0,0);
					triangleStream.Append(o);
					
					o.vertex = UnityObjectToClipPos(lid0);
					o.normal = nor;
					o.color = 1;
					o.texcoord = float4(0,1,0,0);
					triangleStream.Append(o);

					triangleStream.RestartStrip();
				}

				//Side - 1 & 2 = id 1 =======================================================
				
				if(longestLengthid != 1)
				{
					o.color = 1;
					nor = calculateNormal(lid1, v2,v1 );

					o.vertex = UnityObjectToClipPos(v1);
					o.normal = nor;
					o.color = _GroundColor;
					o.texcoord = float4(1,0,0,0);
					triangleStream.Append(o);

					o.vertex = UnityObjectToClipPos(v2);
					o.normal = nor;
					o.color = _GroundColor;
					o.texcoord = float4(0,0,0,0);
					triangleStream.Append(o);

					o.vertex = UnityObjectToClipPos(lid1);
					o.normal = nor;
					o.color = 1;
					o.texcoord = float4(1,1,0,0);
					triangleStream.Append(o);
					
					o.vertex = UnityObjectToClipPos(lid2);
					o.normal = nor;
					o.color = 1;
					o.texcoord = float4(0,1,0,0);
					triangleStream.Append(o);

					triangleStream.RestartStrip();
				}
				
				//Side - 0 & 1 = id 0 =======================================================
				
				if(longestLengthid != 0)
				{
					o.color = 1;
					nor = calculateNormal(lid0, v1,v0 );

					o.vertex = UnityObjectToClipPos(v0);
					o.normal = nor;
					o.color = _GroundColor;
					o.texcoord = float4(1,0,0,0);
					triangleStream.Append(o);

					o.vertex = UnityObjectToClipPos(v1);
					o.normal = nor;
					o.color = _GroundColor;
					o.texcoord = float4(0,0,0,0);
					triangleStream.Append(o);

					o.vertex = UnityObjectToClipPos(lid0);
					o.normal = nor;
					o.color = 1;
					o.texcoord = float4(1,1,0,0);
					triangleStream.Append(o);
					
					o.vertex = UnityObjectToClipPos(lid1);
					o.normal = nor;
					o.color = 1;
					o.texcoord = float4(0,1,0,0);
					triangleStream.Append(o);

					triangleStream.RestartStrip();
				}
			}

			fixed4 frag (g2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex,i.texcoord) * i.color;

				//Light
				i.normal = normalize(i.normal);
				i.normal = mul(unity_ObjectToWorld,i.normal);
				float3 lightDir = -_WorldSpaceLightPos0.xyz;
				float4 lightColor = _LightColor0;
				float lightFactor = DotClamped(lightDir, i.normal);
				float4 light = lightFactor* lightColor;

				return col + light;
			}
			ENDCG
		}
	}
}
