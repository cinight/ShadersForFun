Shader "Unlit/RadialCircle"
{
	Properties
	{
		_SizeOut ("_SizeOut",Range(0,0.5)) = 0.5
		_SizeIn ("_SizeIn",Range(0,0.5)) = 0.5
		_MainTex ("Main Texture", 2D) = "white" {}
		_Progress ("_Progress" ,Range(0,1)) = 0.5
		_Combine ("_Combine",Range(0,25)) = 0.5
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
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

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _SizeOut, _SizeIn, _Progress, _Combine;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			float smin( float a, float b, float k )
			{
				float res = exp( -k*a ) + exp( -k*b );
				return -log( res )/k;
			}
			
			#define PI 3.14159

			fixed4 frag (v2f i) : SV_Target
			{
				float2 uv = i.uv - 0.5;
				float dir = frac(atan2(uv.x,uv.y) / (PI*2));
				float t = abs(_SinTime.z);
				//float t = _Progress;

				float ring = distance(uv,0);
				ring = step(ring,_SizeOut) * (1 -step(ring, _SizeIn));

				float centerRadius = (_SizeOut - _SizeIn) / 2.0f;
				float ringCenter =  centerRadius + _SizeIn;
				float progresspoint = step(dir,t);

				//ring * progresspoint = progress without head

				float2 up = float2(0,1);
				float angle = (1-t) * 2 * PI;
				float2 rotatedvector;
				rotatedvector.x = -sin(angle); //up.x * cos (angle) - up.y * sin (angle);
				rotatedvector.y = cos(angle); //up.y * cos (angle) + up.x * sin (angle);
				float2 huv = rotatedvector * ringCenter;
				float head = distance(uv,huv);
				float shead = step(head,centerRadius);

				//ring * progresspoint + head = progress with one head (moving)

				float2 hhuv = float2(0,ringCenter);
				float headt = distance(uv,hhuv);
				float sheadt = step(headt,centerRadius);

				//ring * progresspoint + head + headt = progress with two head (moving + top one)

				float combinedhead = 1 - smin(head - centerRadius, headt - centerRadius, _Combine);
				combinedhead = 1 - step(combinedhead , 1);
				combinedhead *= step (1-t,0.5f); //only merge at last end
				combinedhead *= ring; //limit to only in the ring

				//combinedhead + shead + sheadt + ring * progresspoint = progress with smoothing heads

				float4 col = saturate(combinedhead + shead + sheadt + ring * progresspoint);
				clip(col.a-0.01f);

				col.rgb *= 1-tex2D(_MainTex,uv + 0.5f);
				col.r *= distance(rotatedvector,huv);
				col.g *= distance(rotatedvector,hhuv);
				col.b *= lerp(0,1,t);

				return col;
			}
			ENDCG
		}
	}
}
