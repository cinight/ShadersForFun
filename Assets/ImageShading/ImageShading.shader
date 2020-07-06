Shader "Custom/ImageShading"
{
    Properties
    {
        [Header(Hair Color)]
        _Col1 ("_Col1", Color) = (1,1,1,1)
        _Brightness1 ("_Brightness1", Range(0,2)) = 1
        _Contrast1 ("_Contrast1", Range(0,2)) = 1

        [Header(Cloth Color)]
        _Col2 ("_Col2", Color) = (1,1,1,1)
        _Brightness2 ("_Brightness2", Range(0,2)) = 1
        _Contrast2 ("_Contrast2", Range(0,2)) = 1

        [Header(Gold Color)]
        _Col3 ("_Col3", Color) = (1,1,1,1)
        _Brightness3 ("_Brightness3", Range(0,2)) = 1
        _Contrast3 ("_Contrast3", Range(0,2)) = 1

        [Header(Iris Color)]
        _Col4 ("_Col4", Color) = (1,1,1,1)
        _Brightness4 ("_Brightness4", Range(0,2)) = 1
        _Contrast4 ("_Contrast4", Range(0,2)) = 1

        [Header(Ruby Color)]
        _Col5 ("_Col5", Color) = (1,1,1,1)
        _Brightness5 ("_Brightness5", Range(0,2)) = 1
        _Contrast5 ("_Contrast5", Range(0,2)) = 1

        [Header(Metal Color)]
        _Col6 ("_Col6", Color) = (1,1,1,1)
        _Brightness6 ("_Brightness6", Range(0,2)) = 1
        _Contrast6 ("_Contrast6", Range(0,2)) = 1

        // _Col7 ("_Col7", Color) = (1,1,1,1)
        // _Brightness7 ("_Brightness7", Range(0,2)) = 1
        // _Contrast7 ("_Contrast7", Range(0,2)) = 1

        [Header(Base)]
        [NoScaleOffset] _SketchTex ("_SketchTex", 2D) = "white" {}
        [NoScaleOffset] _AlbedoTex ("_AlbedoTex", 2D) = "white" {}
        [NoScaleOffset] _AlphaTex ("_AlphaTex", 2D) = "white" {}
        [NoScaleOffset] _ColorMaskTex ("_ColorMaskTex", 2D) = "white" {}

        [Header(Lighting)]
        _ColLight ("_ColLight", Color) = (0.5,0.5,0,1)
        _ColAmbient ("_ColAmbient", Color) = (0.2,0.2,0.2,1)
        [NoScaleOffset] _2LevelTex ("_2LevelTex", 2D) = "white" {}

        [Header(AO)]
        [NoScaleOffset] _AOTex ("_AOTex", 2D) = "white" {}

        [Header(Retouch)]
        _HighlightStrength ("_HighlightStrength", Range(0,5)) = 1
        [NoScaleOffset] _HighlightTex ("_HighlightTex", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Back Lighting Off ZWrite Off
        LOD 100

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

            sampler2D _SketchTex;
            sampler2D _AlbedoTex;
            sampler2D _AlphaTex;
            sampler2D _ColorMaskTex;
            sampler2D _2LevelTex;
            sampler2D _AOTex;
            sampler2D _HighlightTex;

            float4 _Col1;
            float4 _Col2;
            float4 _Col3;
            float4 _Col4;
            float4 _Col5;
            float4 _Col6;
            float4 _Col7;

            float _Brightness1;
            float _Brightness2;
            float _Brightness3;
            float _Brightness4;
            float _Brightness5;
            float _Brightness6;
            float _Brightness7;

            float _Contrast1;
            float _Contrast2;
            float _Contrast3;
            float _Contrast4;
            float _Contrast5;
            float _Contrast6;
            //float _Contrast7;

            float4 _ColLight;
            float4 _ColAmbient;
            float _HighlightStrength;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // https://forum.unity.com/threads/special-mask-texture-problem.506864/#post-3308478
            // float GetMask(int id,float mask)
            // {
            //     int maskint = (int)(mask * 255.0f);
            //     int maskRange = 29;
            //     int maskValue = id*30; //7 masks so 30 each
            //     int maskDist = abs(maskint - maskValue);
            //     float masked = maskDist < maskRange ? 1 : 0;
            //     masked *= 1.0-(float)maskDist / (float)maskRange;
            //     return masked;
            // }

            float GetMask(float3 maskColor, float3 maskInput)
            {
                float maskRange = 0.4;

                float3 maskDist = abs(maskInput - maskColor);
                float3 maskPass = maskDist;
                maskPass.r = maskDist.r < maskRange ? 1.0 : 0.0;
                maskPass.g = maskDist.g < maskRange ? 1.0 : 0.0;
                maskPass.b = maskDist.b < maskRange ? 1.0 : 0.0;
                float masked = maskPass.r*maskPass.g*maskPass.b;
                return masked;
            }

            float3 FakeHueShift(float3 ocol, float3 ncol)
            {
                return float3
                (
                    ocol.r-ncol.r*(2*ocol.r-ocol.g-ocol.b),
                    ocol.g-ncol.g*(2*ocol.g-ocol.r-ocol.b),
                    ocol.b-ncol.b*(2*ocol.b-ocol.r-ocol.g)
                );
            }

            float3 Contrast(float3 col, float k) //k=1 is neutral, 0 to 2
            {
                return ((col - 0.5f) * max(k, 0)) + 0.5f;
            }

            float3 Brightness(float3 col, float k) //k=1 is neutral, 0 to 2
            {
                return col * k;
            }

            float3 ColorChange(float3 col, float3 hue, float brightness, float contrast )
            {
                float3 ncol = col;

                ncol = FakeHueShift(ncol,hue);
                ncol = Brightness(ncol,brightness);
                ncol = Contrast(ncol,contrast);

                return ncol;
            }

            // https://elringus.me/blend-modes-in-unity/
            fixed3 BlendOverlay (fixed3 a, fixed3 b)
            {
                fixed3 r = a < .5 ? 2.0 * a * b : 1.0 - 2.0 * (1.0 - a) * (1.0 - b);
                //r.a = b.a;
                return r;
            }

            // https://forum.unity.com/threads/color-dodge.143955/#post-985327
            // fixed3 BlendColorDodge (fixed3 base, fixed3 blend)
            // {
            //     return ((blend == 1.0) ? blend : min(base / (1.0 - blend), 1.0));
            // }

            float4 frag (v2f i) : SV_Target
            {
                float4 sketch = tex2D(_SketchTex, i.uv);
                float3 albedo = tex2D(_AlbedoTex, i.uv).rgb;
                float4 alpha = tex2D(_AlphaTex, i.uv);
                float4 mask = tex2D(_ColorMaskTex, i.uv);
                float4 level = tex2D(_2LevelTex, i.uv);
                float4 ao = tex2D(_AOTex, i.uv);
                float4 highlight = tex2D(_HighlightTex, i.uv);

                albedo = lerp(albedo,ColorChange(albedo,_Col1,_Brightness1,_Contrast1),GetMask(float3(1,0,0),mask));
                albedo = lerp(albedo,ColorChange(albedo,_Col2,_Brightness2,_Contrast2),GetMask(float3(1,1,0),mask));
                albedo = lerp(albedo,ColorChange(albedo,_Col3,_Brightness3,_Contrast3),GetMask(float3(0,1,0),mask));
                albedo = lerp(albedo,ColorChange(albedo,_Col4,_Brightness4,_Contrast4),GetMask(float3(0,1,1),mask));
                albedo = lerp(albedo,ColorChange(albedo,_Col5,_Brightness5,_Contrast5),GetMask(float3(0,0,1),mask));
                albedo = lerp(albedo,ColorChange(albedo,_Col6,_Brightness6,_Contrast6),GetMask(float3(1,0,1),mask));
                //albedo = lerp(albedo,ColorChange(albedo,_Col7,_Brightness7,_Contrast7),GetMask(float3(1,0,0),mask));

                float4 col = 1;
                col.rgb = albedo;
                col = lerp (col*_ColAmbient , col+_ColLight,level);
                col *= ao;
                col.rgb = lerp( col.rgb*(sketch + 0.5) , BlendOverlay( col.rgb*(sketch + 0.5) , sketch) , (1-sketch.r)*0.5 ) ;
                col += highlight * _HighlightStrength;
                col.a = saturate(alpha.r+(1-sketch));
                return col;
            }
            ENDCG
        }
    }
}
