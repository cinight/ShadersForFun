Shader "Unlit/ShadowCastAndReceiveShadow_Forward"
{
    Properties
    {
        _Color ("_Color",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                 float4 pos : SV_POSITION;
                 float4 worldPos : TEXCOORD4;
                 SHADOW_COORDS(5)
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul( unity_ObjectToWorld , v.vertex);
                TRANSFER_SHADOW(o);
                return o;
            }

            float4 _Color;

            fixed4 frag (v2f i) : SV_Target
            {
                //Care about shadow distance
                float zDist = dot(_WorldSpaceCameraPos - i.worldPos, UNITY_MATRIX_V[2].xyz);
                float fadeDist = UnityComputeShadowFadeDistance(i.worldPos, zDist);
                half shadowFade = UnityComputeShadowFade(fadeDist);
                float shadow = saturate (lerp (SHADOW_ATTENUATION(i), 1.0, shadowFade ) );

                return shadow * _Color;
            }
            ENDCG
        }
        //==========================================================
		Pass 
        {
			Tags {"LightMode" = "ShadowCaster"}

			CGPROGRAM

			#pragma target 3.0

			#include "UnityCG.cginc"
			#pragma multi_compile_shadowcaster

			#pragma vertex vert
			#pragma fragment frag

			struct VertexData 
			{
				float4 position : POSITION;
				float3 normal : NORMAL;
			};

			float4 vert (VertexData v) : SV_POSITION 
			{
				float4 position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
				return UnityApplyLinearShadowBias(position);
			}

			half4 frag () : SV_TARGET 
			{
				return 0;
			}

			ENDCG
		}
    }
}
