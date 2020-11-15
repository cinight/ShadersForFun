Shader "Unlit/stereogram"
{
    Properties
    {
        [HideInInspector]_MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset]_PatternTex ("_PatternTex", 2D) = "white" {}
        [NoScaleOffset]_DepthTex ("_DepthTex", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

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

            sampler2D _PatternTex;
            sampler2D _MainTex;
            sampler2D _DepthTex;

            int _CurrentStrip;
            int _NumOfStrips;
            float _DepthFactor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                //reference:
                //https://developer.nvidia.com/gpugems/gpugems/part-vi-beyond-triangles/chapter-41-real-time-stereograms
                //https://www.ime.usp.br/~otuyama/stereogram/basic/index.html

                float2 uv = i.uv;

                //the first reference strip
                if(_CurrentStrip == 0)
                {
                    return tex2D( _PatternTex , uv * _NumOfStrips );
                }

                //don't change anything in previous strip
                float stripWidth = 1/float(_NumOfStrips);
                float stripRangeMin = float(_CurrentStrip) * stripWidth;
                float stripRangeMax = float(_CurrentStrip + 1) * stripWidth;
                if( uv.x < stripRangeMin )
                {
                    return tex2D( _MainTex , uv );
                }

                //depth
                float2 depthUV = uv;
                depthUV.x = depthUV.x * (1+stripWidth) - stripWidth ; //"shrink" it so it fit into remaining strips
                float depth = tex2D(_DepthTex, depthUV).r;
                depth *= _DepthFactor;

                //distort the texture
                uv.x -= stripWidth; //take the previous strip
                uv.x *= 1+depth;
                float4 col = tex2D( _MainTex , uv );

                return col;
            }
            ENDCG
        }
    }
}

