Shader "Custom/NightVision"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_LightSensetivity("Light Sensetivity", Float) = 1000
		_ColorTint("Color Tint", Color) = (1, 1, 1, 1)
		_NoiseScale("Noise Scale", Range(0, 0.1)) = 1
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
				return o;
			}
			
			sampler2D _MainTex, _CameraGBufferTexture0;
			fixed4 _ColorTint;
			fixed _LightSensetivity, _NoiseScale;

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				fixed4 diffuse = tex2D(_CameraGBufferTexture0, i.uv);

				//Get the base luminance of the rendered image, which is now in grayscale
				fixed luminance = Luminance(fixed3(col.r, col.g, col.b));
				luminance += random(i.uv, _NoiseScale);
				col.rgb = fixed3(luminance, luminance, luminance);

				//Now lerp the color between the greyscale, and ceiling set by LightSensetivity
				col.rgb = lerp(col.rgb, fixed3(1, 1, 1) * _LightSensetivity, luminance);

				//Finally, tint the color
				col *= _ColorTint;

				//col.g += random(i.uv, _NoiseScale);

				return col;
			}
			ENDCG
		}
	}
}
