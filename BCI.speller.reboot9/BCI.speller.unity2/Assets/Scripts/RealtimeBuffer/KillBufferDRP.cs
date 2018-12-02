using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class KillBufferDRP : MonoBehaviour {
    
    void Awake()
    {
        System.Diagnostics.Process.Start("CMD.exe", "/k taskkill /IM cmd.exe /T /F");
    }
    
}
