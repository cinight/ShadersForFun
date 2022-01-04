using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Fractal_Loop : MonoBehaviour
{
    public Material mat;
    public Collider mc;

    private Camera cam;
    private RaycastHit hit;
    private float scale = 1f;
    private Vector2 offset = new Vector2(0f,0f);

    void Start()
    {
		//For mouse input
        cam = Camera.main;

        Reset();
    }

    void Update()
    {
        if( Physics.Raycast(cam.ScreenPointToRay(Input.mousePosition), out hit) && hit.collider == mc )
        {
            if ( Input.GetMouseButton(0))
            {
                scale += Time.deltaTime;
            }
            else if(Input.GetMouseButton(1))
            {
                scale -= Time.deltaTime;
            }
            
            float powerScale = Mathf.Pow(scale,3.0f);

            Vector2 uv = hit.textureCoord - Vector2.one * 0.5f;
            float dist = Vector2.Distance(uv,Vector2.zero) * Time.deltaTime * 1f/powerScale * 1.5f;
            offset.x = uv.x > 0? offset.x + dist : offset.x - dist ;
            offset.y = uv.y > 0? offset.y + dist : offset.y - dist ;

            mat.SetFloat("_Scale",powerScale);
            mat.SetVector("_OffsetUV",offset);

        }
    }

    void Reset()
    {
        mat.SetFloat("_Scale",1f);
        mat.SetVector("_OffsetUV",Vector2.zero);
    }

    void OnDestroy()
    {
        Reset();
    }

    void OnDisable()
    {
        Reset();
    }
}
