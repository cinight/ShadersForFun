using UnityEngine;

public class Face : MonoBehaviour 
{
	public Material mat;
	
	void Update () 
	{
		mat.SetFloat("_MousePositionX",Input.mousePosition.x/Screen.width);
		mat.SetFloat("_MousePositionY",Input.mousePosition.y/Screen.height);
	}
}
