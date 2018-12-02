using System.Collections.Generic;
using UnityEngine;
using RealtimeBuffer;
using System.Threading;

public class NetCode1 : GenericFunctions {

    /////////////////////////////////////////////////////// NETCODE BASE

    // ___   _      ___   _      ___   _      ___   _      ___   _
    //[(_)] |=|    [(_)] |=|    [(_)] |=|    [(_)] |=|    [(_)] |=|
    // '-`  |_|     '-`  |_|     '-`  |_|     '-`  |_|     '-`  |_|
    ///mmm/  /     /mmm/  /     /mmm/  /     /mmm/  /     /mmm/  /
    //      |____________|____________|____________|____________|
    //                            |            |            |
    //                        ___  \_      ___  \_      ___  \_
    //                       [(_)] |=|    [(_)] |=|    [(_)] |=|
    //                        '-`  |_|     '-`  |_|     '-`  |_|
    //                       /mmm/        /mmm/        /mmm/

    public const int BUILD_VERSION = 9; // David Ross Painter, 23/09/2018 11:41 PM

    public static int[] lastReadIndex = new int[BufferConfig.nBuffers];
    public bool[] isBufferOpen = new bool[BufferConfig.nBuffers];

    // environment variables

    public static bool isGameRunning = true; // true until quit for thread shutdown
    public static string localIP;
    public static string remoteIP;

    public static string[] IPs = new string[2] { "XX.XX.XX.XX", "YY.YY.YY.YY" }; // local and remote IPs here

    public class BID // IDX
    {
        public const int message = 0;
        public const int status = 1;
        public const int messageR = 2;
        public const int statusR = 3;
        public const int feedback = 4;
    }

    public class BufferConfig
    {

        //public static string userName = System.Security.Principal.WindowsIdentity.GetCurrent().Name;
        public static string userName = "labpc";

        public const int nBuffers = 5; // CHECK THIS NUMBER IS CORRECT!

        public static readonly List<string> name = new List<string> { "message", "status", "messageR", "statusR", "feedback" };
        public static readonly List<string> host = new List<string> { "localIP", "localIP", "remoteIP", "remoteIP", "localIP" }; // substituted below, localIP, remoteIP
        public static readonly List<int> port = new List<int>() { 3333, 4444, 3333, 4444, 2222 };

        public static readonly List<bool> hosted = new List<bool> { true, true, false, false, false }; // start or not
        public static readonly List<int> nChans = new List<int> { 300, 1, 300, 1, 1 };
        public static readonly List<int> nScans = new List<int> { 1, 1, 1, 1, 1 };

        public class Direct
        {
            public static readonly string parent = "C:\\Users\\" + userName + "\\Desktop\\";
            public static readonly string engine = BufferConfig.Direct.parent + "BCI.speller.reboot" + BUILD_VERSION.ToString() + "\\Engine3\\";
            public static readonly string network = BufferConfig.Direct.engine + "Network.Buffer.DRP.24.09.18\\";
            public static readonly string realtimeHack = BufferConfig.Direct.network + "realtimeHack.10.11.17\\";
            public static readonly string fileName = BufferConfig.Direct.network + "IsBufferRunning\\IsBufferRunning\\bin\\Debug\\IsBufferRunning.exe";
        }
    }

    public List<BufferD> buffer = new List<BufferD>();

    // BufferDRP

    public class BufferD // my first class!
    {
        public string name;

        public string host;
        public int port;

        public bool hosted; // true = if local, false if remote

        public int nChans;
        public int nScans;

        public UnityBuffer socket = new UnityBuffer();
        public Header hdr;

        public string bufferString;

        public int i;
    }

    public void StartNetwork(bool isFlush)
    {

        Debug.Log(BufferConfig.Direct.parent);
        Debug.Log(BufferConfig.Direct.engine);
        Debug.Log(BufferConfig.Direct.network);
        Debug.Log(BufferConfig.Direct.realtimeHack);
        Debug.Log(BufferConfig.Direct.fileName);

        // assign IPs

        using (System.Net.Sockets.Socket socket = new System.Net.Sockets.Socket(System.Net.Sockets.AddressFamily.InterNetwork, System.Net.Sockets.SocketType.Dgram, 0))
        {
            socket.Connect("8.8.8.8", 65530);
            System.Net.IPEndPoint endPoint = socket.LocalEndPoint as System.Net.IPEndPoint;
            localIP = endPoint.Address.ToString();
        }

        if (IPs[0] == localIP) // logical inference
        {
            remoteIP = IPs[1];
        }
        else
        {
            remoteIP = IPs[0];
        }

        ConfigureBuffers(isFlush); // configure buffer

    }

    public void ConfigureBuffers(bool isFlush)
    {
        for (int i = 0; i < BufferConfig.nBuffers; i++)
        {

            buffer.Add(new BufferD());

            buffer[i].i = i;
            lastReadIndex[i] = 0; // necessary for messaging interface
            isBufferOpen[i] = false;

            
            buffer[i].name = BufferConfig.name[i];

            if (BufferConfig.host[i] == "localIP")
            {
                buffer[i].host = localIP;
            }
            else if (BufferConfig.host[i] == "remoteIP")
            {
                buffer[i].host = remoteIP;
            }
            else
            {
                buffer[i].host = localIP;
            }

            buffer[i].port = BufferConfig.port[i];

            Debug.Log("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$");

            buffer[i].bufferString = buffer[i].host + ": " + buffer[i].port + ": " + buffer[i].name;


            Debug.Log(buffer[i].bufferString);

            buffer[i].nChans = BufferConfig.nChans[i];
            buffer[i].nScans = BufferConfig.nScans[i];

            // buffer[i].dataType = DataType.FLOAT32;

            buffer[i].hosted = BufferConfig.hosted[i];

            Debug.Log("buffer[" + i + "].nChans = " + buffer[i].nChans);
            Debug.Log("buffer[" + i + "].nScans = " + buffer[i].nScans);
            Debug.Log("buffer[" + i + "].hosted = " + buffer[i].hosted);
            

            if (buffer[i].hosted)
            {
                StartBuffer(buffer[i]);

                if (isFlush)
                {
                    FlushBuffer(buffer[i]);
                }

                isBufferOpen[buffer[i].i] = true;
                //SkipMessageBacklog(buffer[i]);
            }
            else if (!buffer[i].hosted)
            {
                ConnectToRemoteBuffer(buffer[i]);
                //SkipMessageBacklog(buffer[i]);
            }
        }

        Debug.Log("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$");

    }

    public bool IsBufferRunning(BufferD buffer)
    {
        bool isBufferRunning = false;
        var proc = new System.Diagnostics.Process
        {
            StartInfo = new System.Diagnostics.ProcessStartInfo // get process by window name - super dodge - also cannot run directly from unity
            {
                FileName = BufferConfig.Direct.fileName,
                Arguments = buffer.host + " " + buffer.port,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                CreateNoWindow = true
            }
        };

        proc.Start();

        string line = "";

        while (!proc.StandardOutput.EndOfStream)
        {
            line = proc.StandardOutput.ReadLine();
        }

        if (line == "False")
        {
            isBufferRunning = false;
        }
        else if (line == "True")
        {
            isBufferRunning = true;
        }
        else
        {
            isBufferRunning = false;
        }
        return isBufferRunning;
    }


    public void StartBuffer(BufferD buffer)
    {
        
        if (!IsBufferRunning(buffer))
        {
            Debug.Log("attempting start...");
            string cmdTest = "/k cd " + BufferConfig.Direct.realtimeHack + " & buffer.exe " + buffer.host + " " + buffer.port + " -&";
            System.Diagnostics.Process.Start("CMD.exe", cmdTest);
        }
        
        if ( buffer.socket.connect(buffer.host, buffer.port) )
        {
            try {
                // ----- populate header (necessary if hosted)
                buffer.hdr = buffer.socket.getHeader();
                buffer.hdr.nChans = buffer.nChans;
                buffer.hdr.dataType = DataType.FLOAT32;
                buffer.socket.putHeader(buffer.hdr);
            }
            catch (System.Net.Sockets.SocketException){}
            buffer.socket.disconnect();
        }
    }
    
    public void FlushBuffer(BufferD buffer)
    {
        if ( buffer.socket.connect(buffer.host, buffer.port) )
        {
            try
            {
                buffer.socket.flushData();
            }
            catch (System.Net.Sockets.SocketException){}
            buffer.socket.disconnect();
        }
    }

    void SkipMessageBacklog(BufferD buffer)
    {
        lastReadIndex[buffer.i] = -1;

        if (buffer.socket.connect(buffer.host, buffer.port))
        {
            try
            {
                buffer.hdr = buffer.socket.getHeader();
                lastReadIndex[buffer.i] = buffer.hdr.nSamples;
            }
            catch (System.Net.Sockets.SocketException){}
            buffer.socket.disconnect();
        }
    }

    public void ConnectToRemoteBuffer(BufferD buffer)
    {
        new Thread(() => // Create a new Thread
        {
            while (true & isGameRunning) // needs to terminate so socket can be accessed by main thread, otherwise will lock the main thread, presumably on connect; needs to shut down on game termination or will run forever
            {
                //Debug.Log("/////////////////////////////////////////////////////////" + buffer.name + " " + buffer.host + ": " + buffer.port + ". ConnectToRemoteBuffer(BufferD buffer)");

                if (buffer.socket.connect(buffer.host, buffer.port))
                {
                    isBufferOpen[ buffer.i ] = true;
                    break;
                }
                else
                {
                    isBufferOpen[buffer.i] = false;
                }

                Thread.Sleep(100); // be nice
            
            }
        }).Start(); // Start the Thread
    }


    void OnApplicationQuit()
    {
        isGameRunning = false; // end buffer monitor threads
    }

    /////////////////////////////////////////////////////// BCI SPELLER - BUFFER SPECIFIC

    // ___   _      ___   _      ___   _      ___   _      ___   _
    //[(_)] |=|    [(_)] |=|    [(_)] |=|    [(_)] |=|    [(_)] |=|
    // '-`  |_|     '-`  |_|     '-`  |_|     '-`  |_|     '-`  |_|
    ///mmm/  /     /mmm/  /     /mmm/  /     /mmm/  /     /mmm/  /
    //      |____________|____________|____________|____________|
    //                            |            |            |
    //                        ___  \_      ___  \_      ___  \_
    //                       [(_)] |=|    [(_)] |=|    [(_)] |=|
    //                        '-`  |_|     '-`  |_|     '-`  |_|
    //                       /mmm/        /mmm/        /mmm/

    public static string[] keyAlphabet =     {      "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P",
                                                    "A", "S", "D", "F", "G", "H", "J", "K", "L", "<",
                                                    "Z", "X", "C", "V", "B", "N", "M", " " };

    public class CODE // 
    {
        public const int train = 1000; // from feedback
        public const int test = 2000; // from feedback
        public const int busy = 3000; // from feedback

        public const int spelling = 4000; // from Unity
        public const int viewingChat = 5000; // from Unity

        public const int enterKey = 28;
        public const int backspace = 19;
    }

    public float GetStatus(BufferD buffer)
    {
        float status = float.NaN;

        if (buffer.socket.connect(buffer.host, buffer.port))
        {
            try
            {
                Header hdr = buffer.socket.getHeader();
                float[,] data = new float[,] { };
                if (hdr.nSamples > 0)
                {
                    data = buffer.socket.getFloatData(hdr.nSamples - 1, hdr.nSamples - 1);
                    status = data[0, 0];
                    //Debug.Log(data[0, 0]);
                }
                buffer.socket.disconnect();
            }
            catch (System.Net.Sockets.SocketException) { }
        }
        return status;
    }

    public void SendStatus(float status)
    {
        if (buffer[BID.status].socket.connect(buffer[BID.status].host, buffer[BID.status].port))
        {
            float[,] dataToPut = new float[buffer[BID.status].nScans, buffer[BID.status].nChans];
            dataToPut[0, 0] = status;
            buffer[BID.status].socket.putData(dataToPut);
            buffer[BID.status].socket.disconnect();
        }
    }

    public string ReceiveMessageLast(BufferD buffer)
    {
        string message = "";
        if (buffer.socket.connect(buffer.host, buffer.port))
        {
            try
            {
                buffer.hdr = buffer.socket.getHeader();

                if (buffer.hdr.nSamples == 0)
                {
                    return message;
                }

                //Debug.Log(buffer.hdr.nSamples);

                float[,] data = buffer.socket.getFloatData(buffer.hdr.nSamples - 1, buffer.hdr.nSamples - 1);

                for (int i = 0; i < buffer.nChans; i++) // 300
                {
                    if (!float.IsNaN(data[0, i]) & data[0, i] < keyAlphabet.Length) // extra safety check
                    {
                        message += keyAlphabet[(int)data[0, i]];
                    }
                    else
                    {
                        break;
                    }
                }
                //Debug.Log(message);
                buffer.socket.disconnect();
            }
            catch (System.Net.Sockets.SocketException) { }
        }
        return message;
    }

    public string ReceiveMessageIDX2(BufferD buffer, int[] idxSample)
    {
        string message = "";
        if (buffer.socket.connect(buffer.host, buffer.port))
        {
            try
            {
                float[,] data = buffer.socket.getFloatData(idxSample[0], idxSample[1]);
                for (int i = 0; i < buffer.nChans; i++) // 300
                {
                    if (!float.IsNaN(data[0, i]) & data[0, i] < keyAlphabet.Length) // extra safety check
                    {
                        message += keyAlphabet[(int)data[0, i]];
                    }
                    else
                    {
                        break;
                    }
                }
                buffer.socket.disconnect();
            }
            catch (System.Net.Sockets.SocketException) { }
        }
        return message;
    }

    public float[,] CreateRandomMessage()
    {
        float[,] dataToPut = new float[buffer[BID.message].nScans, buffer[BID.message].nChans];
        for (int i = 0; i < buffer[BID.message].nChans; i++) // 300
        {
            if (i < 60)
            {
                dataToPut[0, i] = UnityEngine.Random.Range(0, 27);
                //message += keyAlphabet[(int)dataToPut[0, i]];
            }
            else
            {
                dataToPut[0, i] = float.NaN;
            }
        }
        return dataToPut;
    }


    public void SendMessage(float[,] dataToPut)
    {
        if ( buffer[BID.message].socket.connect( buffer[BID.message].host, buffer[BID.message].port) )
        {
            try
            {
                buffer[BID.message].socket.putData(dataToPut);
                buffer[BID.message].socket.disconnect();
            }
            catch (System.Net.Sockets.SocketException) { }
        }
    }


}
