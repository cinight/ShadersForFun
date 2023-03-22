using UnityEngine;

public class MeshMorph : MonoBehaviour
{
    [Range(0f,1f)] public float progress = 0.5f;
    public Transform mesh1;
    public Transform mesh2;

    private Mesh mesh;
    private Vector3[] vertices;
    private Vector2[] uv2;
    private Color[] colors;
    private Material material;

    private void Start()
    {
        mesh = GetComponent<MeshFilter>().mesh;
        vertices = mesh.vertices;

        // x = distance of mesh1
        // y = distance of mesh2
        uv2 = new Vector2[vertices.Length];

        // rg = uv of mesh1
        // ba = uv of mesh2
        colors = new Color[vertices.Length];

        for (int i = 0; i < vertices.Length; i++)
        {
            RayCast(i, mesh1, 1);
            RayCast(i, mesh2, 2);
        }

        mesh.colors = colors;
        mesh.uv2 = uv2;
        GetComponent<MeshFilter>().sharedMesh = mesh;
        material = GetComponent<Renderer>().sharedMaterial;
    }

    void FixedUpdate()
    {
        progress = Mathf.Sin(Time.fixedTime)*0.5f + 0.5f;
        material.SetFloat("_Progress",progress);
    }

    private void RayCast(int i, Transform src, int meshID)
    {
        Vector3 lpos = vertices[i];
        Vector3 wpos = src.TransformPoint(lpos);
        Vector3 center = src.position;
        Vector3 dir = center - wpos;

        RaycastHit hit;
        if (Physics.Raycast(wpos, dir, out hit, Mathf.Infinity))
        {
            // hit.textureCoord requires to use MeshCollider
            switch(meshID)
            {
                case 1: 
                    uv2[i].x = hit.distance;
                    colors[i].r = hit.textureCoord.x;
                    colors[i].g = hit.textureCoord.y;
                    break;
                case 2: 
                    uv2[i].y = hit.distance;
                    colors[i].b = hit.textureCoord.x;
                    colors[i].a = hit.textureCoord.y;
                    break;
            }
        }
    }
}