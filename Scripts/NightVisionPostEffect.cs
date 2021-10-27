using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class NightVisionPostEffect : MonoBehaviour
{
	public Material nightVisionMat;
	public Material bloom;

	public bool renderNightVision = true;
	public bool renderBloom = true;

	[Range(1, 16)]
	public int iterations = 1;

	const int BoxDownPrefilterPass = 0;
	const int BoxDownPass = 1;
	const int BoxUpPass = 2;
	const int ApplyBloomPass = 3;

	RenderTexture[] textures = new RenderTexture[16];


	void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		//Declare all initial values
		int width = src.width / 2;
		int height = src.height / 2;
		RenderTextureFormat format = src.format;
		RenderTexture nightDest = RenderTexture.GetTemporary(width, height, 0, format);

		//Decide if we render the night vision effect
		if (renderNightVision)
        {
			Graphics.Blit(src, nightDest, nightVisionMat);
		}
        else
        {
			nightDest = src;
        }

		//Decide if we render bloom
        if (!renderBloom)
        {
			Graphics.Blit(nightDest, dest);
			return;
		}


		//Perform the prefilter pass for bloom
		RenderTexture currentDestination = textures[0] = RenderTexture.GetTemporary(width, height, 0, format);
		Graphics.Blit(nightDest, currentDestination, bloom, BoxDownPrefilterPass);
		RenderTexture currentSource = currentDestination;

		//Now go through and downsample the render texture
		for (int i = 1; i < iterations; i++)
		{
			width /= 2;
			height /= 2;
			if (height < 2)
			{
				break;
			}

			currentDestination = textures[i] = RenderTexture.GetTemporary(width, height, 0, format);
			Graphics.Blit(currentSource, currentDestination, bloom, BoxDownPass);
			//RenderTexture.ReleaseTemporary(currentSource);
			currentSource = currentDestination;
		}

		//Now upsample the render texture
		for (int i = iterations - 2; i >= 0; i--)
		{
			currentDestination = textures[i];
			textures[i] = null;
			Graphics.Blit(currentSource, currentDestination, bloom, BoxUpPass);
			RenderTexture.ReleaseTemporary(currentSource);
			currentSource = currentDestination;
		}

		//Finally write all of this to the destination texture
		bloom.SetTexture("_SourceTex", nightDest);
		Graphics.Blit(currentSource, dest, bloom, ApplyBloomPass);
		RenderTexture.ReleaseTemporary(currentSource);
		RenderTexture.ReleaseTemporary(nightDest);

	}
}
