using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Stereogram : MonoBehaviour
{
    public Camera renderCamera;
    public Material blitMaterial;
    [Range(2,24)] public int _NumOfStrips = 10;

    void Start()
    {
        Camera cam = GetComponent<Camera>();
    }
    
    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        float CameraDepth = 1f/(renderCamera.farClipPlane - renderCamera.nearClipPlane);
        blitMaterial.SetFloat("_DepthFactor",CameraDepth);
        blitMaterial.SetInt("_NumOfStrips",_NumOfStrips);
        
        for(int i=0; i<_NumOfStrips; i++)
        {
            blitMaterial.SetInt("_CurrentStrip",i);
            Graphics.Blit( src , src , blitMaterial );
        }
        Graphics.Blit(src,dst);
    }
}
