Shader "Unlit/PrismaticCard"
{
    Properties
    {
        _MainTex ("_MainTex", 2D) = "white" {}
        _MaskTex ("_MaskTex", 2D) = "white" {}
        _BumpTex ("_BumpTex", 2D) = "white" {}
        _RampTex ("_RampTex", 2D) = "white" {}
        _Density("_Density", Range(0, 10)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

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
                float3 nor : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 wViewDir : TEXCOORD1;
                float4 vertex : SV_POSITION;
                float3 nor : NORMAL;
            };

            sampler2D _MainTex;
            sampler2D _MaskTex;
            sampler2D _BumpTex;
            sampler2D _RampTex;

            float4 _MainTex_ST;
            float4 _BumpTex_ST;

            float _Density;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                float3 wpos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.wViewDir = normalize(UnityWorldSpaceViewDir(wpos));
                float3 wnor = mul(unity_ObjectToWorld, v.nor).xyz;
                o.nor = wnor;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv1 = TRANSFORM_TEX(i.uv, _MainTex);
                float2 uv2 = TRANSFORM_TEX(i.uv, _BumpTex);

                fixed4 col = tex2D(_MainTex, uv1);
                fixed4 mask = tex2D(_MaskTex, uv1);
                half3 tnor = UnpackNormal(tex2D(_BumpTex, uv2));

                float3 L = tnor + abs(i.nor);
                float3 V = i.wViewDir;

                float factor =  dot(L, V);
                factor *= _Density;
                float3 rcol = tex2D(_RampTex, float2(factor,0.5f));

                float4 result = col;
                result.rgb *= rcol * 2;
                result.rgb += col;

                return lerp(col,result,mask);
            }
            ENDCG
        }
    }
}
