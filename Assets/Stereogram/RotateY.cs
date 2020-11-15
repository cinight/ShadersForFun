using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateY : MonoBehaviour
{
    public float speed = 10f;

    void LateUpdate()
    {
        this.transform.RotateAround(Vector3.zero,Vector3.up,Time.deltaTime*speed);
    }
}
