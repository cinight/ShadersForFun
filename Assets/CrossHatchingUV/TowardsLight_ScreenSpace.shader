Shader "Unlit/Mapping Lightdir Screenspace"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
                //float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 wnor : NORMAL;
            };

            #define PI 3.1415926535897932384626433832795

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float2 RotateUV(float2 uv, float angle)
            {
                float2 center = 0.5;
                float2 offset = uv - center;
                float2 rotated = float2(offset.x * cos(angle) - offset.y * sin(angle), offset.x * sin(angle) + offset.y * cos(angle));
                return rotated + center;
            }

            float Angle2D(float2 a, float2 b)
            {
                float2 delta = a - b;
                float angle = atan2(delta.y, delta.x);
                return angle;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.wnor = mul( unity_ObjectToWorld, v.normal);
                o.uv = ComputeScreenPos(o.pos);

                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 lightDir = normalize(_WorldSpaceLightPos0);
                i.uv.xy = i.uv.xy / i.uv.w; //screenspace uv

                float4 directionCS = mul(UNITY_MATRIX_VP, lightDir);
                float angle = Angle2D(directionCS.xy,0);
                i.uv.xy = RotateUV(i.uv.xy, angle);

                float diffuse = dot(i.wnor, lightDir.xyz);
                i.uv.xy = TRANSFORM_TEX(i.uv.xy, _MainTex);
                float4 col = tex2D(_MainTex, i.uv.xy) * diffuse;
                return col;
            }
            ENDCG
        }
    }
}