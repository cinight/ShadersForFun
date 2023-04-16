Shader "Unlit/Triplanar"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TriplanarBlendSharpness ("Blend Sharpness",float) = 1
        _Contrast ("Contrast",Range(0,1)) = 0
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
                float4 pos : SV_POSITION;
                float3 nor : NORMAL;
                float3 vpos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _TriplanarBlendSharpness;
            float _Contrast;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.vpos = v.vertex;
                o.nor = v.normal;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {               
                // ref Martin Palko - http://www.martinpalko.com/Tutorials/TriplanarMapping/TriplanarMapping.html

                float2 yUV = TRANSFORM_TEX(i.vpos.xz, _MainTex);
                float2 xUV = TRANSFORM_TEX(i.vpos.zy, _MainTex);
                float2 zUV = TRANSFORM_TEX(i.vpos.xy, _MainTex);

                float4 yDiff = tex2D (_MainTex, yUV);
                float4 xDiff = tex2D (_MainTex, xUV);
                float4 zDiff = tex2D (_MainTex, zUV);

                float3 blendWeights = pow (abs(i.nor), _TriplanarBlendSharpness);
                blendWeights = blendWeights / (blendWeights.x + blendWeights.y + blendWeights.z);
                float4 result = xDiff * blendWeights.x + yDiff * blendWeights.y + zDiff * blendWeights.z;

                // Adding contrast
                result *= lerp(1.0, result * 3.0, _Contrast); 

                return result;
            }
            ENDCG
        }
    }
}