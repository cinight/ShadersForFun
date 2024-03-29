﻿//Good Fractal learning resources:
//http://nuclear.mutantstargoat.com/articles/sdr_fract/
//https://darkeclipz.github.io/fractals/paper/Fractals%20&%20Rendering%20Techniques.html
//https://www.youtube.com/watch?v=6IWXkV82oyY
//https://www.iquilezles.org/www/index.htm
//http://paulbourke.net/fractals/fracintro/

Shader "Custom/Fractal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [IntRange] _Iteration("_Iteration",Range(1,300)) = 10
        [Toggle(_TOGGLE_REPEAT)] _Repeat("_Repeat", Float) = 0
        [KeywordEnum(Julia, Mandelbrot, Custom1, Custom2, Custom3, Custom4, Custom5, Custom6)] _Fractal("_Fractal",Float) = 0
        _cX("_cX",Range(-2,2)) = -1.1
        _cY("_cY",Range(-2,2)) = -1.1
        _cX2("_cX2",Range(-2,2)) = -1.1
        _cY2("_cY2",Range(-2,2)) = -1.1
        _SmoothStep("_SmoothStep",Range(0,2)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _FRACTAL_JULIA _FRACTAL_MANDELBROT _FRACTAL_CUSTOM1 _FRACTAL_CUSTOM2 _FRACTAL_CUSTOM3 _FRACTAL_CUSTOM4 _FRACTAL_CUSTOM5 _FRACTAL_CUSTOM6
            #pragma multi_compile _ _TOGGLE_REPEAT

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
            float _cX,_cY;
            float _cX2,_cY2;
            float _SmoothStep;

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
                float2 z = uv;
                float2 c = float2(_cX,_cY);
                float2 c2 = float2(_cX2,_cY2);
                float F = 0.0f;

                for(uint i=0; i<_Iteration; i++) 
                {
                    #if _TOGGLE_REPEAT
                        z = abs(z);
                    #endif

                    float2 n = 1;
                    //Fractal types
                    #if _FRACTAL_JULIA
                        n = c_mul(z,z) + c;
                    #elif _FRACTAL_MANDELBROT
                        n = c_mul(z,z) + uv;
                    #elif _FRACTAL_CUSTOM1
                        #if _TOGGLE_REPEAT
                            uv = abs(uv);
                        #endif
                        n = c_mul( z-1 , c_mul(z,c) );
                    #elif _FRACTAL_CUSTOM2
                        n = c_mul(frac(z-c),frac(z*c));
                    #elif _FRACTAL_CUSTOM3
                        n = c_mul(atan(z),z+c);
                    #elif _FRACTAL_CUSTOM4
                        n = c_mul(z,z+c);
                    #elif _FRACTAL_CUSTOM5
                        n = c_mul(sin(z) , z*c2) + c;
                    #elif _FRACTAL_CUSTOM6
                        n = c_mul(z,z) + c;
                        n.x += min( c2.x, length(z-n) );
                        n.y += min( c2.y, length(z-n) );
                    #endif

                    //Bounds
                    if( c_mag(n) > 10000.0f )
                    {
                        break;
                    }
                    
                    z = n;
                    F = i;
                    
                }

                //Fractal value - smooth
                //https://darkeclipz.github.io/fractals/paper/Fractals%20&%20Rendering%20Techniques.html
                float Folog = log(dot(z, z));
                float FologAbs = abs(Folog); //prevent inside getting NaN
                float Fo = F - log( FologAbs / log(4.0)) / log(2.0);
                Fo = Fo / (float)_Iteration;
                Fo = frac(Fo + 0.5f);
                Fo = ((Fo - 0.5f) * max(_SmoothStep, 0)) + 0.5f; //adjust contrast

                //Fractal uv outside
                float4 colo = tex2D(_MainTex, float2(Fo,0.5f));
                //float2 Fuvo = abs(uv*Fo*5.0f);
                //Fuvo = frac(Fuvo);
                //float4 colo = tex2D(_MainTex, Fuvo);
                
                //Fractal uv inside
                float2 Fuv = abs(z * F);
                Fuv *= _SmoothStep * 0.1f;
                float4 coli = tex2D(_MainTex, Fuv);

                //Result color
                float lp = sign(Folog)+1;
                lp *= Fo;
                float4 col = lerp(coli,colo,lp);
                return col;
            }
            ENDCG
        }
    }
}
