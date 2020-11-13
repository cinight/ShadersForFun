Shader "Unlit/stereogram"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset]_DepthTex ("_DepthTex", 2D) = "white" {}
        _Strips ("_Strips",Range(10,20)) = 10
        _DepthFactor ("_DepthFactor",Range(0.1,100)) = 1
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
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _DepthTex;
            float4 _DepthTex_ST;

            int _Strips;
            float _DepthFactor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = v.uv; //For DepthTex

                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                //https://developer.nvidia.com/gpugems/gpugems/part-vi-beyond-triangles/chapter-41-real-time-stereograms

                float b = 1/float(_Strips);
                float c = 1/float(_Strips+1);

                float2 ouv = i.uv.zw;

                float2 depthUV = ouv;
                depthUV.x = b * ( ouv.x / c-1 );
                float depth = tex2D(_DepthTex, depthUV).r;
                depth = depth*c*_DepthFactor;

                float2 newUV = float2( i.uv.x+depth-c , i.uv.y );
                float4 col = tex2D( _MainTex , newUV );

                return col;
            }
            ENDCG
        }
    }
}