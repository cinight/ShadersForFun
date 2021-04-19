//Good Fractal learning resources:
//https://darkeclipz.github.io/fractals/paper/Fractals%20&%20Rendering%20Techniques.html
//https://www.youtube.com/watch?v=6IWXkV82oyY

Shader "Custom/Fractal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [IntRange] _Iteration("_Iteration",Range(1,50)) = 10
        _cX("_cX",Range(-2,1)) = -1.1
        _cY("_cY",Range(-2,1)) = -1.1
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
            int _Iteration;
            float _cX,_cY;
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
                float F=0.0f;

                for(int i=0; i<_Iteration; i++) 
                {
                    //Julia
                    float2 n = c_mul(z,z) + c;

                    //Mandelbrot
                    //float2 n = c_mul(z,z) + uv;

                    //Custom1
                    //float2 n = c_mul(z,uv) + c_mul(z,z) + c_cjg(c);
                    
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
                float4 colo = Fo;
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
