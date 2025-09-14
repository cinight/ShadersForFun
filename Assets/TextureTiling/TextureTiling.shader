Shader "Custom/TextureTiling"
{
    Properties
    {
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
        _Tiling ("Tiling", Float) = 2
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;

            float _Tiling;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;//TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // Tiling
                float2 uv = i.uv;
                uv *= _Tiling;
                uv = frac(uv);

                // Get mip level - https://discussions.unity.com/t/calculate-used-mipmap-level-ddx-ddy/542839/22
                float2 uvForMipSelection = i.uv * _Tiling;
                float2 dx = ddx(uvForMipSelection * _MainTex_TexelSize.z);
                float2 dy = ddy(uvForMipSelection * _MainTex_TexelSize.w);
                float md = max(dot(dx,dx), dot(dy,dy));
                float lod = log2(md)*0.5;

                // Sample texture
                float4 sampleuv = float4(uv, 0, lod);
                float4 col = tex2Dlod(_MainTex, sampleuv);
                
                // This has edge artifacts
                //float4 col = tex2D(_MainTex, uv);

                return col;
            }
            ENDCG
        }
    }
}
