Shader "Custom/NightVisionAdvanced"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_LightSensetivity("Light Sensetivity", Float) = 1000
		_ColorTint("Color Tint", Color) = (1, 1, 1, 1)
		_NoiseScale("Noise Scale", Range(0, 0.5)) = 1
		_DistanceScale("Distance Scale", Range(0, 1)) = 1
		_DistanceOffset("Distance Offset", Range(0, 1)) = 1
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

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
				float4 scrPos : TEXCOORD1;
			};

			float random (float2 uv, float scale)
            {
				uv = uv * float2(_SinTime.x, _SinTime.y);
                return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123) * scale;
            }

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.scrPos = ComputeScreenPos(o.vertex);
				return o;
			}
			

			sampler2D _MainTex, _CameraGBufferTexture0, _CameraDepthTexture;
			fixed4 _ColorTint;
			float _LightSensetivity, _NoiseScale, _DistanceScale, _DistanceOffset;

			fixed4 frag (v2f i) : SV_Target
			{
				
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				depth = LinearEyeDepth(depth);
				
				depth = log(depth + 1) * _DistanceScale;
				depth = _DistanceOffset - depth;
				
				fixed4 col = tex2D(_MainTex, i.uv);
				fixed4 diffuse = tex2D(_CameraGBufferTexture0, i.uv);

				//Get the base luminance of the rendered image, which is now in grayscale
				fixed luminance = Luminance(col.rgb);

				luminance = luminance * _LightSensetivity;

				//return fixed4(depth, depth, depth, 1);

				luminance = max(depth, luminance);

				//return fixed4(luminance, luminance, luminance, 1);

				luminance += random(i.uv, _NoiseScale);
				col.rgb = fixed3(luminance, luminance, luminance);

				//Now lerp the color between the greyscale, and ceiling set by LightSensetivity
				//col.rgb = lerp(col.rgb, fixed3(1, 1, 1) * _LightSensetivity, luminance);

				//Finally, tint the color
				col *= _ColorTint;

				return col;
			}
			ENDCG
		}
	}
}
