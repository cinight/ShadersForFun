Shader "Custom/Fractal Loop"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [IntRange] _Iteration("_Iteration",Range(1,300)) = 10
        _Scale("_Scale",Range(0.01,10)) = 1
        _OffsetUV("_OffsetUV",Vector) = (0,0,0,0)
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
            #include "ComplexOp.cginc"

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
            uint _Iteration;
            float _Scale;
            float2 _OffsetUV;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.uv.xy += _MainTex_ST.zw;
                o.uv.xy *= _MainTex_ST.xy;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                uv += _OffsetUV * _Scale;
                uv /= _Scale;

                float2 z = uv;
                float F = 0.0f;
                float maxF = 0.0f;

                for(uint i=0; i<_Iteration; i++) 
                {
                    float2 n = c_mul(z,z) + uv;

                    //Bounds
                    if( c_mag(n) > 10000.0f )
                    {
                        break;
                    }
                    
                    z = n;
                    F = i;
                    maxF = max(maxF,F);
                }

                return (maxF) / (float)_Iteration;
            }
            ENDCG
        }
    }
}
