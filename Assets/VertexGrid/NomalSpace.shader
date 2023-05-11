Shader "Custom/NormalSpace"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Brightness ("Brightness", Range(0,100)) = 1
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
                float4 vertex : SV_POSITION;

                float3 normal : NORMAL;
                nointerpolation float3 normal_no : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Brightness;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.normal = v.normal;
                o.normal_no = o.normal;

                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);

                float3 nor = i.normal;
                float3 nor_no = i.normal_no;

                //https://forum.unity.com/threads/matrix-rotation-with-normal-vector-in-shader.1391479/#post-8762269
                float3 up = nor_no;
                float3 forward = float3(0,0,1);
                float3 right = normalize(cross(up, forward));
                forward = cross(right, up);
                float3x3 rotMatrix = float3x3(right, up, forward);
 
                //all faces on the same plane
                nor = mul(rotMatrix, float4(nor,1));
                nor_no = mul(rotMatrix, float4(nor_no,1));

                //gradient
                float3 dist_nor = abs(nor - nor_no);
                dist_nor *= _Brightness;
                col.rgb = dist_nor; //dist_nor.y;

                return col;
            }
            ENDCG
        }
    }
}
