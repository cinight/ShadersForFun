Shader "Custom/Eye"
{
    Properties
    {
        _MainTex ("_MainTex (rgb: base a: mask)", 2D) = "white" {}
        [NoScaleOffset] _DepthTex ("_DepthTex (r: shadow a: depth)", 2D) = "white" {}
        [NoScaleOffset] _ReflTex ("_ReflTex (rgba)", 2D) = "white" {}
        _Intensity("_Intensity",Range(0,1)) = 1
        _Intensity_Normal("_Intensity_Normal",Range(1,10)) = 1
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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 viewDir : TEXCOORD1;
                float3 wnor : NORMAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DepthTex;
            sampler2D _ReflTex;
            float _Intensity;
            float _Intensity_Normal;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float3 wpos = mul(unity_ObjectToWorld, v.vertex);
                o.viewDir = UnityWorldSpaceViewDir(wpos);
                o.wnor = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float mask = tex2D(_MainTex, i.uv).a;
                float4 depthTex = tex2D(_DepthTex, i.uv);
                float shadow = depthTex.r;
                float depth = depthTex.a;

                float3 viewDir = normalize(i.viewDir);
                float3 uvDir = normalize(mul(unity_WorldToObject, float4(viewDir,0)).xyz);
                
                //concave
                float2 uv = i.uv;
                float factor = dot(viewDir * _Intensity_Normal, i.wnor);
                factor = saturate(factor);
                uv -= (1.0-depth) * uvDir.xy * lerp(_Intensity_Normal,_Intensity,factor);
                float4 col = tex2D(_MainTex, uv);
                
                //convex
                uv = i.uv;
                uv += (1.0-depth) * uvDir.xy *_Intensity;
                float4 refl = tex2D(_ReflTex, uv);

                float4 result = col * shadow;
                result = lerp(0.5, result, mask) + refl * refl.a;

                return result;
            }
            ENDCG
        }
    }
}
