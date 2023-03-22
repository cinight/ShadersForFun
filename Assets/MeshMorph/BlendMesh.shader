Shader "Unlit/BlendMesh"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Progress ("_Progress", Range(0,1)) = 0.5
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
                float2 uv2 : TEXCOORD1;
                float4 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Progress;

            v2f vert (appdata v)
            {
                v2f o;
                
                float3 lpos = v.vertex;
                float3 dir = 0 - lpos;

                float3 lpos1 = lpos + dir * v.uv2.x;
                float3 lpos2 = lpos + dir * v.uv2.y;

                lpos = lerp(lpos1,lpos2,_Progress);
                o.vertex = UnityObjectToClipPos(lpos);

                float2 uv1 = v.color.rg;
                float2 uv2 = v.color.ba;

                v.uv = lerp(uv1,uv2,_Progress);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
