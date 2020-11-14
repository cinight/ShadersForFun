using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Stereogram : MonoBehaviour
{
    public Material blitMaterial;
    [Range(2,24)] public int _NumOfStrips = 10;

    private RenderTexture tex;

    void Start()
    {
        Camera cam = GetComponent<Camera>();
    }

    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {       
        for(int i=0; i<_NumOfStrips; i++)
        {
            blitMaterial.SetInt("_CurrentStrip",i);
            blitMaterial.SetInt("_NumOfStrips",_NumOfStrips);

            Graphics.Blit( src , src , blitMaterial );
        }
        Graphics.Blit(src,dst);
    }
}
