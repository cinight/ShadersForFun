Shader "Custom/VID 01"
{
    Properties
    {

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
                uint id : SV_VertexID;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;

                float4 uv0 : TEXCOORD0; 
			    nointerpolation float4 uv0_no : TEXCOORD1;
                float4 uv1 : TEXCOORD2;
			    nointerpolation float4 uv1_no : TEXCOORD3;
                float4 uv2 : TEXCOORD4;
                nointerpolation float4 uv2_no : TEXCOORD5;
                float4 uv3 : TEXCOORD6;
                nointerpolation float4 uv3_no : TEXCOORD7;
                float4 uv4 : COLOR;
                nointerpolation float4 uv4_no : TEXCOORD8;
            };

            float4 SetUVFromID(int vid, int pow)
            {
                float4 uv = 0;
                uv.r = ((vid & pow) == pow); pow*=2;
                uv.g = ((vid & pow) == pow); pow*=2;
                uv.b = ((vid & pow) == pow); pow*=2;
                uv.a = ((vid & pow) == pow);
                return uv;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;

                int vid = v.id; //2^20 channels = max 1048575 vertices

                o.uv0 = SetUVFromID(vid,1);
                o.uv1 = SetUVFromID(vid,2^4);
                o.uv2 = SetUVFromID(vid,2^8);
                o.uv3 = SetUVFromID(vid,2^12);
                o.uv4 = SetUVFromID(vid,2^16);

                o.uv0_no = o.uv0;
                o.uv1_no = o.uv1;
                o.uv2_no = o.uv2;
                o.uv3_no = o.uv3;
                o.uv4_no = o.uv4;

                return o;
            }

            float CalCol(float a, float a_no)
            {
                return abs(a);
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = 0;

                float sameSum = 0;

                //========================
                float4 uv0 = 1;
                if( i.uv0.r != i.uv0_no.r )
                {   
                    uv0.r = CalCol(i.uv0.r,i.uv0_no.r);
                    sameSum++;
                }
                if( i.uv0.g != i.uv0_no.g )
                {   
                    uv0.g = CalCol(i.uv0.g,i.uv0_no.g );
                    sameSum++;
                }
                if( i.uv0.b != i.uv0_no.b )
                {   
                    uv0.b = CalCol(i.uv0.b,i.uv0_no.b);
                    sameSum++;
                }
                if( i.uv0.a != i.uv0_no.a )
                {   
                    uv0.a = CalCol(i.uv0.a,i.uv0_no.a);
                    sameSum++;
                }
                //========================
                float4 uv1 = 1;
                if( i.uv1.r != i.uv1_no.r )
                {   
                    uv1.r = CalCol(i.uv1.r,i.uv1_no.r);
                    sameSum++;
                }
                if( i.uv1.g != i.uv1_no.g )
                {   
                    uv1.g = CalCol(i.uv1.g,i.uv1_no.g);
                    sameSum++;
                }
                if( i.uv1.b != i.uv1_no.b )
                {   
                    uv1.b = CalCol(i.uv1.b,i.uv1_no.b);
                    sameSum++;
                }
                if( i.uv1.a != i.uv1_no.a )
                {   
                    uv1.a = CalCol(i.uv1.a,i.uv1_no.a);
                    sameSum++;
                }
                //========================
                float4 uv2 = 1;
                if( i.uv2.r != i.uv2_no.r )
                {   
                    uv2.r = CalCol(i.uv2.r,i.uv2_no.r);
                    sameSum++;
                }
                if( i.uv2.g != i.uv2_no.g )
                {   
                    uv2.g = CalCol(i.uv2.g,i.uv2_no.g);
                    sameSum++;
                }
                if( i.uv2.b != i.uv2_no.b )
                {   
                    uv2.b = CalCol(i.uv2.b,i.uv2_no.b);
                    sameSum++;
                }
                if( i.uv2.a != i.uv2_no.a )
                {   
                    uv2.a = CalCol(i.uv2.a,i.uv2_no.a);
                    sameSum++;
                }
                //========================
                float4 uv3 = 1;
                if( i.uv3.r != i.uv3_no.r )
                {   
                    uv3.r = CalCol(i.uv3.r,i.uv3_no.r);
                    sameSum++;
                }
                if( i.uv3.g != i.uv3_no.g )
                {   
                    uv3.g = CalCol(i.uv3.g,i.uv3_no.g);
                    sameSum++;
                }
                if( i.uv3.b != i.uv3_no.b )
                {   
                    uv3.b = CalCol(i.uv3.b,i.uv3_no.b);
                    sameSum++;
                }
                if( i.uv3.a != i.uv3_no.a )
                {   
                    uv3.a = CalCol(i.uv3.a,i.uv3_no.a);
                    sameSum++;
                }
                //========================
                float4 uv4 = 1;
                if( i.uv4.r != i.uv4_no.r )
                {   
                    uv4.r = CalCol(i.uv4.r,i.uv4_no.r);
                    sameSum++;
                }
                if( i.uv4.g != i.uv4_no.g )
                {   
                    uv4.g = CalCol(i.uv4.g,i.uv4_no.g);
                    sameSum++;
                }
                if( i.uv4.b != i.uv4_no.b )
                {   
                    uv4.b = CalCol(i.uv4.b,i.uv4_no.b);
                    sameSum++;
                }
                if( i.uv4.a != i.uv4_no.a )
                {   
                    uv4.a = CalCol(i.uv4.a,i.uv4_no.a);
                    sameSum++;
                }
                //========================
                
                float f0 = min(min(min(uv0.r, uv0.g), uv0.b), uv0.a);
                float f1 = min(min(min(uv1.r, uv1.g), uv1.b), uv1.a);
                float f2 = min(min(min(uv2.r, uv2.g), uv2.b), uv2.a);
                float f3 = min(min(min(uv3.r, uv3.g), uv3.b), uv3.a);
                float f4 = min(min(min(uv4.r, uv4.g), uv4.b), uv4.a);
                
                float f = min(f0,f1);
                      f = min(f,f2);
                      f = min(f,f3);
                      f = min(f,f4);

                return f;
            }
            ENDCG
        }
    }
}
