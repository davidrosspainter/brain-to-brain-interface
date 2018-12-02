using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CentralBrain : MonoBehaviour {


    const int BUILD_VERSION = 4;

    // Use this for initialization
    void Start () {
		
	}








    public class BufferConfig
    {

        public static readonly int nBuffers = 4;

        public static readonly List<string> name = new List<string> { "frameData", "feedback", "P1", "P2" };

        // PC #1 = "10.50.72.32"
        // PC #2 = "10.50.74.66"

        public static readonly List<string> host = new List<string> { "127.0.0.1", "127.0.0.1", "127.0.0.1", "10.50.74.66" };
        public static readonly List<int> port = new List<int>() { 10000, 7777, 1, 1 }; // CHANNEL: feedback, frameData, P1, P2

        public static readonly List<bool> hosted = new List<bool> { true, false, true, false }; // false = read or not create

        public static readonly List<int> nChans = new List<int> { 11, 1, 1, 1 };
        public static readonly List<int> nScans = new List<int> { 1, 1, 1, 1 };

        public class Direct
        {
            public static readonly string engine = "C:\\Users\\labpc\\Desktop\\BCI.speller.reboot" + BUILD_VERSION.ToString() + "\\Engine3\\";
            public static readonly string realtimeHack = BufferConfig.Direct.engine + "\\toolboxes\\interComputerBuffer.4\\realtimeHack.10.11.17\\";
        }
         
        public static readonly string fileName = BufferConfig.Direct.realtimeHack + "\\IsBufferRunning\\IsBufferRunning\\bin\\Debug\\IsBufferRunning.exe";



    }








}
