Shader "Unlit/Voronoi"
{
    Properties
    {
        _Size("_Size",Range(0,5)) = 1
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

            float _Size;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float2 random2( float2 p ) 
            {
                return frac(sin(float2(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3))))*43758.5453);
            }

            #define COUNT 6
            #define PI 3.1415926536

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = 0;

                //=======================================================
                //Shader is from https://thebookofshaders.com/12/
                //=======================================================
                float2 uv = i.uv;
                uv *= _Size;
                uv -= 0.5f * _Size;

                float m_dist = 1.0; // minimun distance

                // Iterate through the points positions
                for (int i = 0; i < COUNT; i++)
                {
                    //A random position
                    float2 p = random2(float(i)/float(COUNT));
                    
                    // Animate the point
                    p = 0.5*sin(_Time.y + 6.2831*p);

                    float dist = distance(uv,p);

                    // Keep the closer distance
                    m_dist = min(m_dist,dist);
                }

                // Draw the min distance (distance field)
                col.rgb += m_dist;
                //=======================================================

                return col;
            }
            ENDCG
        }
    }
}