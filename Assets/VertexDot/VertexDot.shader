Shader "Custom/VertexDot"
{
    Properties
    {
        [NoScaleOffset] _MainTex ("_Ramp", 2D) = "white" {}
        _ID ("_ID", Range(2,20)) = 0
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
                uint vid : SV_VertexID;
            };

            struct v2f
            {
                float4 color : COLOR;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float _ID;

            v2f vert (appdata v)
            {
                v2f o;
                float factor = abs(sin(v.vid%_ID*(v.vertex.r+v.vertex.g+v.vertex.b+sin(_Time.y))));
                o.color = factor;
                v.vertex.y += factor*2;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, float2(i.color.r, 0.5));
                return col;
            }
            ENDCG
        }
    }
}
