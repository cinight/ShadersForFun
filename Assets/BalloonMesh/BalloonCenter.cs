using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class BalloonCenter : MonoBehaviour
{
    public Material material;
    public Transform center;

    void Start()
    {
        
    }

    void Update()
    {
        if(material != null)
        {
            material.SetVector("_Center", center.position);
        }
    }
}
