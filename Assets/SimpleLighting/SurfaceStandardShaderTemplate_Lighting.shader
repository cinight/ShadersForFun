Shader "ShaderForFun/Surface Standard Shader - Lighting"
{
	Properties 
	{
		[Header(Custom)]
		_Amount("Extrusion Amount", Range(-1,1)) = 0.5

		[Header(Albedo)]
		_Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}

		//[Header(Gloss)]
       // _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
        
        //[Enum(Metallic Alpha,0,Albedo Alpha,1)] _SmoothnessTextureChannel ("Smoothness texture channel", Float) = 0

		[Header(Metallic)]
        //[Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		[NoScaleOffset] _MetallicGlossMap("Metallic", 2D) = "white" {}

        //[ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
       // [ToggleOff] _GlossyReflections("Glossy Reflections", Float) = 1.0

		[Header(Normal)]
        _BumpScale("Scale", Float) = 1.0
		[NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}

		[Header(Height)]
		[Toggle(_HEIGHT)] _EnableHeight("Enable Height?", Float) = 0 //Toggle
			[HideIfDisabled(_HEIGHT)] _Parallax ("Height Scale", Range (0.005, 0.08)) = 0.02
			[HideIfDisabled(_HEIGHT)] [NoScaleOffset] _ParallaxMap ("Height Map", 2D) = "black" {}

		[Header(Occlussion)]
        _OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
		[NoScaleOffset] _OcclusionMap("Occlusion", 2D) = "white" {}

		[Header(Emission)]
		[Toggle(_EMISSION)] _EnableEmission("Enable Emission?", Float) = 1 //Toggle
			[HideIfDisabled(_EMISSION)] [HDR] _EmissionColor("Color", Color) = (0,0,0)
			[HideIfDisabled(_EMISSION)] [NoScaleOffset] _EmissionMap("Emission", 2D) = "white" {}

		[Enum(On,0,Off,1)]	_EnableGlossyReflections("Glossy Reflections?", int) = 0
		[Enum(On,0,Off,1)]	_EnableSpecularHighlight("Specular Highlight?", int) = 0
		[KeywordEnum(BRDF1, BRDF2, BRDF3)] _Select("Keyword Enum", Float) = 0

	}

	CGINCLUDE
	#define UNITY_SETUP_BRDF_INPUT MetallicSetup

	#define _NORMALMAP 1
    //#define _EMISSION 1
    #define _METALLICGLOSSMAP 1
   //#define _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A 1

    #define _SPECULARHIGHLIGHTS_OFF [_EnableGlossyReflections]
    #define _GLOSSYREFLECTIONS_OFF [_EnableSpecularHighlight]

	//#define _SpecularHighlights 1f
    // #define _DETAIL_MULX2 1
	
    #define UNITY_BRDF_PBS BRDF1_Unity_PBS
    //#define UNITY_BRDF_PBS BRDF2_Unity_PBS
    //#define UNITY_BRDF_PBS BRDF3_Unity_PBS
    ENDCG

	SubShader 
	{
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Custom finalcolor:final fullforwardshadows vertex:vert
		#pragma target 3.0
		#pragma shader_feature _ _EMISSION
		#pragma shader_feature _ _HEIGHT

		#include "UnityStandardInput.cginc"
		#include "UnityStandardCore.cginc"
		#include "UnityPBSLighting.cginc"

		struct Input 
		{
			float4 texcoords;
			float3 viewDir;
		};

		float _Amount;
		float _SpecularHighlights;

		void vert (inout appdata_full v, out Input o) 
	    {
	          UNITY_INITIALIZE_OUTPUT(Input,o);

	          UNITY_SETUP_INSTANCE_ID (v);
		      v.vertex.xyz += v.normal * _Amount;

			   o.texcoords.xy = TRANSFORM_TEX(v.texcoord.xy, _MainTex); // Always source from uv0
			   o.texcoords.zw = v.texcoord.zw;
	    }

		void surf (Input IN, inout SurfaceOutputStandard o) 
		{
			
			float4 texcoords = IN.texcoords;

			//Parallax
			#if _HEIGHT
				half h = tex2D(_ParallaxMap, texcoords.xy).r;
				texcoords.xy += ParallaxOffset(h,_Parallax, IN.viewDir);
			#endif

			o.Albedo = Albedo(texcoords) * _Color;

			o.Normal = NormalInTangentSpace(texcoords);
			o.Normal = NormalizePerPixelNormal(o.Normal);

			o.Emission = Emission(texcoords.xy) * _EmissionColor.a;

			//half ma = tex2D(_MetallicGlossMap, texcoords.xy).a;
			half2 metallicGloss = MetallicGloss(texcoords.xy);// * ma;
			o.Metallic = metallicGloss.x;//* _Metallic; // _Metallic;
			o.Smoothness = metallicGloss.y;// *_Glossiness; // _Glossiness;

			o.Occlusion = Occlusion(texcoords.xy);

			o.Alpha = tex2D(_MainTex, IN.texcoords.xy).a;
		}

		void final (Input IN, SurfaceOutputStandard o, inout fixed4 color)
		{
		   color = OutputForward(color, color.a);
		}

		inline fixed4 LightingCustom(SurfaceOutputStandard s, fixed3 viewDir, UnityGI gi)
		{
			// Original colour
			fixed4 pbr = LightingStandard(s, viewDir, gi);

			// Calculate intensity of backlight (light translucent)
			//float I = ...
			//pbr.rgb = pbr.rgb + gi.light.color * I;

			return pbr;
		}

		inline void LightingCustom_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
		{
			// Original colour
			LightingStandard_GI(s, data, gi);
		}

		ENDCG
		UsePass "Standard/SHADOWCASTER"
		UsePass "Standard/META"
	}
}
