using System.IO;
using System.Linq;
using UnityEngine;
using System.Collections.Generic;

public class GenericFunctions : MonoBehaviour {

    // output

    public void CreateOutFile(string FNAME, bool delete)
    {
        if (File.Exists(FNAME) & delete)
        {
            File.Delete(FNAME);
            UnityEngine.Debug.Log(FNAME);
            using (StreamWriter sw = File.CreateText(FNAME)) { };
        }
        else if (!File.Exists(FNAME))
        {
            using (StreamWriter sw = File.CreateText(FNAME)) { };
        }
    }

    public void WriteString(string array, string pathFNAME)
    {
        using (StreamWriter sw = new StreamWriter(pathFNAME, true))
        {
            sw.Write(array);
        }
    }

    protected void Write2D(float[,] array, string pathFNAME, string header)
    {
        int nRows = array.GetUpperBound(0) - array.GetLowerBound(0) + 1;
        int nCols = array.GetUpperBound(1) - array.GetLowerBound(1) + 1;
        if (!File.Exists(pathFNAME))
        {
            using (StreamWriter sw = File.CreateText(pathFNAME))
            {

                sw.Write(header);

                for (int i = 0; i < nRows; i++)
                {
                    string content = "";
                    for (int j = 0; j < nCols; j++)
                    {
                        content += array[i, j].ToString() + ",";
                    }
                    content = content.Substring(0, content.Length - 1);
                    sw.WriteLine(content);
                }
            }
        }

        using (StreamWriter sw = File.AppendText(pathFNAME))
        {
            for (int i = 0; i < nRows; i++)
            {
                string content = "";
                for (int j = 0; j < nCols; j++)
                {
                    content += array[i, j].ToString() + ",";
                }
                content = content.Substring(0, content.Length - 1);
                sw.WriteLine(content);
            }
        }
    }

    public float[] LinSpace(float d1, float d2, int n)
    {
        int nl = n - 1;

        float[] y = new float[nl + 1];

        for (int i = 0; i <= nl; i++)
        {
            y[i] = d1 + i * (d2 - d1) / nl;
        }

        return y;
    }

    public System.Random rnd = new System.Random();

    public int[] RandPerm(int n, System.Random rnd)
    {
        //Debug.Log("RandPerm");
        var idx = Enumerable.Range(1, n).OrderBy(r => rnd.Next()).ToArray();
        return idx;
    }

    // triggers

    public class Trig
    {

        public static List<int> cue = new List<int> { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29 }; // 29 = test
        public static List<int> flick = new List<int> { 101, 102, 103, 104, 105, 106, 107, 108, 109, 1010, 1011, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129 }; // 29 = test

        public static int startRecording = 254;
        public static int stopRecording = 255;

        public static int viewingChat = 150;

    }

    // parallel port

    public void SetupPort()
    {
        for (int i = 0; i < Port.address.Length; i++)
        {
            Port.port[i] = System.Convert.ToInt32(Port.address[i], 16);
        }
    }

    public class Port
    {
        public static string[] address = new string[2] { "2FF8", "21" };
        //public static string[] address = new string[2] { "D030", "D010" };
        public static int[] port = new int[2];
    }

    public class PortAccess
    {
        [System.Runtime.InteropServices.DllImport(dllName: "inpoutx64.dll", EntryPoint = "Out32")]
        public static extern void Output(int address, int value);

        [System.Runtime.InteropServices.DllImport(dllName: "inpoutx64.dll", EntryPoint = "Inp32")]
        public static extern char Input(int address);
    }




}
