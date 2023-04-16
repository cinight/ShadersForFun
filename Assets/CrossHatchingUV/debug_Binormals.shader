// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Debug/Binormals" 
{
    SubShader 
    {
        Pass 
        {
            Fog { Mode Off }
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // vertex input: position, normal, tangent
            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float4 color : COLOR;
            };
            
            v2f vert (appdata v) {
                v2f o;
                o.pos = UnityObjectToClipPos( v.vertex );
                // calculate binormal
                float3 binormal = cross( v.normal, v.tangent.xyz ) * v.tangent.w;
                o.color.xyz = binormal * 0.5 + 0.5;
                o.color.w = 1.0;
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target { return i.color; }
            ENDCG
        }
    }
}