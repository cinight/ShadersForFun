Shader "Unlit/PrismaticCard"
{
    Properties
    {
        _Color ("_Color", color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _MaskTex ("_MaskTex", 2D) = "white" {}
        _BumpTex ("_BumpTex", 2D) = "white" {}
        [NoScaleOffset] _RampTex ("_RampTex", 2D) = "white" {}
        _Distance("_Distance", Range(0, 10)) = 1
        _Strength("_Strength", Range(0, 5)) = 1
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
                //float3 nor : NORMAL;
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                //float3 wnor : NORMAL;
                float2 uv : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _MaskTex;
            sampler2D _RampTex;
            sampler2D _BumpTex;
            float4 _BumpTex_ST;

            float4 _Color;
            float _Distance;
            float _Strength;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                float3 wpos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.viewDir = normalize(UnityWorldSpaceViewDir(wpos));
                //o.wnor = mul(unity_ObjectToWorld, v.nor).xyz;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                //Main texture
                float2 uvMain = TRANSFORM_TEX(i.uv, _MainTex);
                float4 col = tex2D(_MainTex, uvMain) * _Color;
                float mask = tex2D(_MaskTex, uvMain).r;

                //Normal map
                float2 uvBump = TRANSFORM_TEX(i.uv, _BumpTex);
                float3 bump = UnpackNormal(tex2D(_BumpTex, uvBump));
                float3 wbump = normalize(mul(unity_ObjectToWorld, float4(bump, 0)));

                //Diffraction Grating from https://www.alanzucconi.com/2017/07/15/cd-rom-shader-2/
                // float3 L = dot(i.wnor, _WorldSpaceLightPos0.xyz);
                // float3 V = i.viewDir;
                // float3 T = wbump;
                // float cos_ThetaL = dot(L, T);
                // float cos_ThetaV = dot(V, T);
                // float u = abs(cos_ThetaL - cos_ThetaV);
                // float w = u * _Distance;

                float3 L = wbump;
                float3 V = i.viewDir;
                float Theta = dot(L, V);
                float u = abs(Theta);
                float w = u * _Distance;

                //Rainbow color
                float3 prismastic =  tex2D(_RampTex, float2(w,0.5f));

                //Blend the colors
                float4 result = col;
                result.rgb += prismastic * _Strength;
                result = lerp(col,result,mask);

                //Apply Mask
                return result;
            }
            ENDCG
        }
    }
}
