Shader "Unlit/SampleMipmap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Smoothness("Smoothness", Range(0, 1)) = 0.5
        _MipMapCount("MipMapCount", float) = 9 //Texture.mipmapCount
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
            float _Smoothness;
            float _MipMapCount;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float mip = _Smoothness * _MipMapCount;
                float4 col = tex2Dlod(_MainTex, float4(i.uv, 0 , mip));
                float4 col2 = tex2Dlod(_MainTex, float4(i.uv, 0 , mip+0.5));
                float4 c = lerp(col, col2, 0.5);
                return c;
            }
            ENDCG
        }
    }
}
