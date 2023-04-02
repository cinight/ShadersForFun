Shader "Unlit/BallonMesh"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Test ("Test", Range(0,1)) = 1
        _Radius ("_Radius", Range(0,3)) = 1
        _Center ("_Center", Vector) = (1,1,1,1)
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
            float3 sphereCenter;
            float _Test;
            float _Radius;
            float3 _Center;

            v2f vert (appdata v)
            {
                v2f o;
                float3 lpos = v.vertex;

                float3 newPos = 0;
                float3 center = _Center * _Radius;
                float3 dirToCenter = normalize(lpos - center);
                newPos = dirToCenter * _Radius * 0.5;

                lpos = lerp(lpos,newPos,_Test);

                float3 wpos = mul (unity_ObjectToWorld, float4(lpos,1));

                o.vertex = UnityWorldToClipPos(wpos);
                o.uv = v.uv;
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
