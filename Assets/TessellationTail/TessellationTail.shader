Shader "Custom/TessellationTail" 
{
    Properties 
	{
		[Header(Movement)]
		_VDist("Vert Distplace", Range(0,10)) = 1
        _TessEdge ("Edge Tess", Range(1,5)) = 2
		_Speed ("Speed", Range(0,5)) = 2
		_NormalFactor ("NormalFactor", Range(0.001,1)) = 0.05
		
		//[Header(Color)]
		//_FillColor("FillColor", Color) = (0,0,0,0)
    }
    SubShader 
	{
		Tags { "RenderType"="Opaque" }

		CGINCLUDE //For shared tessellation and vertex functions ====================================================================

			#include "UnityCG.cginc"
			#include "UnityStandardBRDF.cginc"

			float _VDist;
			float _TessEdge;
			float _Speed;
			float _NormalFactor;

			float4 VertexDisplacement(float4 pos)
			{
				float tailFactor = 1-(pos.x + 0.5f);

				//Wave for pos y
				float wave_idle = sin( tailFactor * 20.0f - _Time.z * _Speed ) * _VDist * tailFactor;
				pos.y += wave_idle;

				return pos;
			}

			//Idea from Adrian Myers https://www.youtube.com/watch?v=1G37-Yav2ZM
			float3 RecalculateNormal(float4 v0 , float3 nor)
			{
				//Fake neighbor vertices
				float3 v1 = v0.xyz + float3( 0.05f, 0, 0 ); //+X 
				float3 v2 = v0.xyz + float3( 0, 0, 0.05f ); //+Z

				//Apply same Vertex Displacement method
				v1 = VertexDisplacement(float4(v1,0));
				v2 = VertexDisplacement(float4(v2,0));

				//Smoothing
				v1.y -= (v1.y - v0.y) * _NormalFactor; 
				v2.y -= (v2.y - v0.y) * _NormalFactor;

				float3 vna = cross( v2-v0.xyz, v1-v0.xyz );
				vna.y *= sign(nor.y);

				float3 vn = mul((float3x3)unity_WorldToObject, vna); 
				vn = normalize( vn ); 

				return vn;
			}

    		struct VS_In
    		{
        		float4 vertex : POSITION;
				float4 nor : NORMAL;
				float4 texcoord : TEXCOORD0;
    		};
     
    		struct HS_In
    		{
        		float4 pos   : INTERNALTESSPOS;
				float4 nor : NORMAL;
				float4 texcoord : TEXCOORD0;
    		};
     
	 		#ifdef UNITY_CAN_COMPILE_TESSELLATION
				struct HS_ConstantOut
				{
					float TessFactor[3]    : SV_TessFactor;
					float InsideTessFactor : SV_InsideTessFactor;
				};
			#endif
     
    		struct HS_Out
    		{
        		float4 pos    : INTERNALTESSPOS;
				float4 nor : NORMAL;
				float4 texcoord : TEXCOORD0;
    		}; 
     
    		HS_In VS( VS_In i )
    		{
        		HS_In o;
				o.pos = i.vertex;
				o.nor = i.nor;
				o.texcoord = i.texcoord;
        		return o;
    		}
    
			#ifdef UNITY_CAN_COMPILE_TESSELLATION
				HS_ConstantOut HSConstant( InputPatch<HS_In, 3> i )
				{
					HS_ConstantOut o = (HS_ConstantOut)0;
					o.TessFactor[0] = _TessEdge;
					o.TessFactor[1] = _TessEdge;
					o.TessFactor[2] = _TessEdge;
					o.InsideTessFactor = _TessEdge;    
					return o;
				}

				[UNITY_domain("tri")]
				[UNITY_partitioning("integer")]
				[UNITY_outputtopology("triangle_cw")]
				[UNITY_patchconstantfunc("HSConstant")]
				[UNITY_outputcontrolpoints(3)]
				HS_Out HS( InputPatch<HS_In, 3> i, uint uCPID : SV_OutputControlPointID )
				{
					HS_Out o = (HS_Out)0;
					o.pos = i[uCPID].pos;
					o.nor = i[uCPID].nor;
					o.texcoord = i[uCPID].texcoord;
					return o;
				}
			#endif
		
		ENDCG

    	Pass  //For shading ======================================================================================================
		{
			Tags {"LightMode" = "ForwardBase" }

    		CGPROGRAM
    		#pragma target 4.6
    		#pragma vertex VS
    		#pragma fragment PS
			#ifdef UNITY_CAN_COMPILE_TESSELLATION
				#pragma hull HS
				#pragma domain DS
			#endif

			//uniform fixed4 _FillColor;

			#ifdef UNITY_CAN_COMPILE_TESSELLATION
    		struct DS_Out
    		{
        		float4 pos    : SV_POSITION;
				float4 nor : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 color : COLOR;
    		};   

			//Calculate Normal from triagle points
			float3 CalculateNormal( float3 vecN , float3 vecE , float3 vecS , float3 vecW )
			{
				float3 nor = ( cross(vecN, vecE) + cross(vecE, vecS) + cross(vecS, vecW) + cross(vecW, vecN) ) / 4;
				nor = normalize( nor );
				nor = nor * 0.5f + 0.5f;

				return nor;
			}

			[UNITY_domain("tri")]
			DS_Out DS( HS_ConstantOut HSConstantData, 
						const OutputPatch<HS_Out, 3> i, 
						float3 BarycentricCoords : SV_DomainLocation)
			{
				DS_Out o = (DS_Out)0;
	
				float fU = BarycentricCoords.x;
				float fV = BarycentricCoords.y;
				float fW = BarycentricCoords.z;

				float4 pos = i[0].pos * fU + i[1].pos * fV + i[2].pos * fW;
				pos = VertexDisplacement(pos);
				o.pos = UnityObjectToClipPos(pos);

				float3 nor = i[0].nor * fU + i[1].nor * fV + i[2].nor * fW;
				//nor = normalize(nor);
				//nor = UnityObjectToWorldNormal(nor);
				o.nor = float4(RecalculateNormal(pos,nor), 0.0);

				float4 texcoord = i[0].texcoord * fU + i[1].texcoord * fV + i[2].texcoord * fW;
				o.texcoord = texcoord;

				o.color = float4(pos.x,0,0,1);

				return o;
			}
			#endif

    		float4  PS(DS_Out i) : SV_Target
    		{
				float4 color = i.color;

				// Light
				float3 lightDir = _WorldSpaceLightPos0.xyz;
				float lightFactor = DotClamped(lightDir, i.nor);
				float4 light = _LightColor0 * lightFactor;
				color = color + light;
 
       			return color;
    		}
     
    		ENDCG
    	}
		
        Pass // Pass to render object as a shadow caster ======================================================================================
     	{
			Name "ShadowCaster"
			Tags{ "Queue" = "Transparent" "LightMode" = "ShadowCaster"  }

         	CGPROGRAM
    		#pragma target 4.6
    		#pragma vertex VS
    		#pragma fragment PS
			#ifdef UNITY_CAN_COMPILE_TESSELLATION
				#pragma hull HS
				#pragma domain DS
			#endif
			#pragma multi_compile_shadowcaster
			#pragma fragmentoption ARB_precision_hint_fastest

			#ifdef UNITY_CAN_COMPILE_TESSELLATION
    		struct DS_Out
    		{
        		float4 pos    : SV_POSITION;
    		};   

			[UNITY_domain("tri")]
			DS_Out DS( HS_ConstantOut HSConstantData, 
						const OutputPatch<HS_Out, 3> i, 
						float3 BarycentricCoords : SV_DomainLocation)
			{
				DS_Out o = (DS_Out)0;
	
				float fU = BarycentricCoords.x;
				float fV = BarycentricCoords.y;
				float fW = BarycentricCoords.z;

				float3 nor = i[0].nor * fU + i[1].nor * fV + i[2].nor * fW;
				float4 pos = i[0].pos * fU + i[1].pos * fV + i[2].pos * fW;
				
				pos = VertexDisplacement(pos);


				float4 wPos = mul(unity_ObjectToWorld, pos);
				float3 wNormal = normalize(mul(nor, (float3x3)unity_WorldToObject));

					float3 wLight = normalize(_WorldSpaceLightPos0.xyz);

					float shadowCos = dot(wNormal, wLight);
					float shadowSine = sqrt(1-shadowCos*shadowCos);
					float normalBias = unity_LightShadowBias.z * shadowSine;

					wPos.xyz -= wNormal * normalBias;

				o.pos = mul(UNITY_MATRIX_VP, wPos);
				o.pos = UnityApplyLinearShadowBias(o.pos);
		
				return o;
			}
			#endif
 
			float4 PS (DS_Out i) : SV_Target
			{
				return 0;
			}
 
         	ENDCG
    	}
    }
	
}