Shader "Unlit/HDRP_Decal"
{
    Properties
    {
        [MainColor] _BaseColor("Color", Color) = (0.5,0.5,0.5,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "HDRenderPipeline" }

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "Forward" }
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/DecalUtilities.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 normalWS : NORMAL;
                float4 tangentWS : TANGENT;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.tangentWS = float4(TransformObjectToWorldDir(v.tangentOS.xyz), v.tangentOS.w);
                o.uv = v.uv;
                return o;
            }

			UNITY_INSTANCING_CBUFFER_SCOPE_BEGIN(UnityPerMaterial) //SRPBatcher
			float4 _BaseColor;
			UNITY_INSTANCING_CBUFFER_SCOPE_END //SRPBatcher

            float4 frag (v2f i) : SV_Target
            {
				float4 col = _BaseColor;

                PositionInputs posInput;
                posInput.positionSS = uint2(i.positionCS.xy);
                
                float3x3 tangentToWorld = BuildTangentToWorld(i.tangentWS, i.normalWS.xyz);
                float3 vtxNormal = tangentToWorld[2];
                float alpha = 1.0; // unused
                
                DecalSurfaceData decalSurfaceData = GetDecalSurfaceData(posInput, vtxNormal, GetMeshRenderingLayerMask(), alpha);

                col.rgb = decalSurfaceData.baseColor.rgb;
				
				return col;
            }
            ENDHLSL
        }
        UsePass "HDRP/Lit/DEPTHONLY"
    }
}