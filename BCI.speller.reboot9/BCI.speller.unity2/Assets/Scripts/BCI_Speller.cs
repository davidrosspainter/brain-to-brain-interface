using System.Collections.Generic; // list
using RealtimeBuffer; // UnityBuffer, Hdr
using UnityEngine; // Debug.Log, MonoBehaviour
using System.Threading; // Thread
using System.Linq; // enumerable range, contains
using System.IO;
using System;
using TMPro;

public class BCI_Speller : NetCode1 {


    // training
    int[] target = new int[nTrials];

    const int nBlocks = 1000; // impossibly large number - run forever!
    const int nTrials = nHz * nBlocks; // pre-allocate numerous cues for virtual photodiode

    public const int nBlocksTrain = 15;
    const int nTrialsTrain = nHz * nBlocksTrain;


    // quality

    static int targetFrameRate = 144; // Hz
    int vSyncCount = 1;

    private void SetQuality() // speed settings!!!
    {
        Application.targetFrameRate = targetFrameRate; // run at medium quality with 640x480 resolution
        QualitySettings.vSyncCount = vSyncCount;
        QualitySettings.maxQueuedFrames = 2;
        QualitySettings.SetQualityLevel(0); // seems to be the magic formula
    }

    // options

    [Header("Options")]
    public bool isTrain = true;
    public bool isWaitMatlab = true;
    public bool isCheckPhotoOnset = false;
    public bool isStopRecording = false;
    public bool isPhotoDiode = false; // real photodiode!
    public bool isVirtualPhotodiode = false;
    public bool isFakeSwitch = true;
    public bool isDebugging = true;
    public bool isFlush = false;
    
    // environment variables - BCI

    public static float statusR;

    bool isViewingChat = false;
    float letterClassified; // float for nan
    bool isTestingNow;

    public int TRIAL = -1;
    public int FRAME = -1; // check, originally Frames.trial

    bool isPaused = false;
    bool isGameStarted = false;

    // flicker

    const int nHz = 28;

    float HzAdjust = 0;

    float HzMin = 08.0f;
    float HzMax = 15.8f;
    //float HzInc = 00.2f;

    float[] HzAll; // defined in start

    float[] thetaAll = new float[] {0.00f, 0.35f, 0.70f, 1.05f, 1.40f, 1.75f, 0.10f, 0.45f,
                                    0.80f, 1.15f, 1.50f, 1.85f, 0.20f, 0.55f, 0.90f, 1.25f,
                                    1.60f, 1.95f, 0.30f, 0.65f, 1.00f, 1.35f, 1.70f, 0.05f,
                                    0.40f, 0.75f, 1.10f, 1.45f, 1.80f, 0.15f, 0.50f, 0.85f,
                                    1.20f, 1.55f, 1.90f, 0.25f, 0.60f, 0.95f, 1.30f, 1.65f }; // 40 possibilities

    int[] selectedHz = {    10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
                            20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
                            30, 31, 32, 33, 34, 35, 36, 37, 38 }; // -1! relative to MATLAB

    float[] Hz = new float[nHz]; // selected
    float[] theta = new float[nHz]; // selected

    float LUM = 0;

    // -------------------------------- timing

    System.Diagnostics.Stopwatch sw = new System.Diagnostics.Stopwatch();

    float flickerTime;
    System.Diagnostics.Stopwatch stopwatchFlicker = new System.Diagnostics.Stopwatch();

    public class Sec
    {
        [SerializeField]
        public static float cue = 0.75f; // 0.2014
        public static float flicker = 1.5f; // 0.2014

        public static float trigger = 0.0278f*2; // 0.0278 (4 trigger frames)
        public static float startPause = 1.0f;
    }

    public class Frames
    {
        public static int cue = (int)Math.Round(Sec.cue * targetFrameRate);
        public static int flicker = (int)Math.Round(Sec.flicker * targetFrameRate);
        public static int trial = Frames.flicker + Frames.cue;

        public static int trigger = (int)Math.Round(Sec.trigger * targetFrameRate);
        public static int startPause = (int)Math.Round(Sec.startPause * targetFrameRate);
    }

    // change matrix

    public class CM // change matrix
    {
        public static List<int> frames;
        public static List<int> stimulus;
        public static List<int> trigger;
    }

    private void ChangeMatrix()
    {
        CM.frames = new List<int>();
        CM.frames.AddRange(Enumerable.Range(0, Frames.cue));
        CM.frames.AddRange(Enumerable.Range(0, Frames.flicker));

        CM.stimulus = new List<int>();
        CM.stimulus.AddRange(Enumerable.Repeat(1, Frames.cue).ToList());
        CM.stimulus.AddRange(Enumerable.Repeat(2, Frames.flicker).ToList());

        CM.trigger = new List<int>();
        CM.trigger.AddRange(Enumerable.Repeat(1, Frames.trigger).ToList());
        CM.trigger.AddRange(Enumerable.Repeat(0, Frames.cue - Frames.trigger).ToList());
        CM.trigger.AddRange(Enumerable.Repeat(1, Frames.trigger).ToList());
        CM.trigger.AddRange(Enumerable.Repeat(0, Frames.flicker - Frames.trigger).ToList());
    }

    // output

    string outFileCM; // change matrix
    string outFileFD; // frame data
    string outFilePhrases; // phrases
    string outFileChatLog; // chat log

    private void TextLog()
    {
        // output .txt files

        string[] tmpOFB = System.IO.File.ReadAllLines(BufferConfig.Direct.engine + "DataResults\\lastExperiment.txt");
        string outFileBase = tmpOFB[0];

        outFileCM = outFileBase + ".ChangeMatrix.txt";
        CreateOutFile(outFileCM, true);

        if (File.Exists(outFileCM))
        {
            File.Delete(outFileCM);
        }

        WriteString("frames,stimulus,trigger\n", outFileCM);

        for (int i = 0; i < Frames.trial; i++)
        {
            WriteString(CM.frames[i].ToString() + ",", outFileCM);
            WriteString(CM.stimulus[i].ToString() + ",", outFileCM);
            WriteString(CM.trigger[i].ToString() + ",", outFileCM);
            WriteString("\n", outFileCM);
        }

        // phrases

        outFilePhrases = outFileBase + ".Phrases.txt";
        CreateOutFile(outFilePhrases, false);

        outFileFD = outFileBase + ".FrameData.txt";
        CreateOutFile(outFileFD, false);

        outFileChatLog = outFileBase + ".ChatLog.txt";
        CreateOutFile(outFileChatLog, false);

        Debug.Log(outFileCM);
        Debug.Log(outFilePhrases);
        Debug.Log(outFileFD);
        Debug.Log(outFileChatLog);
    }

    // KEYBOARD SPRITES

    public GameObject tmpPhotodiode;
    static SpriteRenderer PHOTODIODE;

    static SpriteRenderer[] key = new SpriteRenderer[nHz];
    static SpriteRenderer[] cue = new SpriteRenderer[nHz];
    static SpriteRenderer[] ph = new SpriteRenderer[nHz];
    static TextMeshProUGUI[] statusText = new TextMeshProUGUI[nHz];

    static GameObject outputWindow;
    TextMeshProUGUI outputText;

    // ----- SPRITE COLLECTIONS

    static GameObject BUBBLES;

    static GameObject PH;
    static GameObject CUE;
    static GameObject KEY;
    static GameObject LETTER;
    static GameObject STATUS;


    GameObject chatIcon;

    private void ConfigureStim()
    {

        // game objects

        outputWindow = GameObject.Find("outputWindow");

        BUBBLES = GameObject.Find("BUBBLES");

        outputText = GameObject.Find("OutputWindowText").GetComponent<TextMeshProUGUI>();
        outputText.text = "";

        //PHOTODIODE = GameObject.Find("PHOTODIODE").GetComponent<SpriteRenderer>();
        PHOTODIODE = tmpPhotodiode.GetComponent<SpriteRenderer>();
        PHOTODIODE.enabled = false;

        chatIcon = GameObject.Find("chatIcon");
        chatIcon.SetActive(false);

        // ----- SPRITE COLLECTIONS

        PH = GameObject.Find("PH");
        CUE = GameObject.Find("CUE");
        KEY = GameObject.Find("KEY");
        LETTER = GameObject.Find("LETTER");
        STATUS = GameObject.Find("STATUS");

        // sprites

        HzAll = LinSpace(HzMin, HzMax, 40);

        for (int i = 0; i < nHz; i++)
        {

            Hz[i] = HzAll[selectedHz[i]];
            theta[i] = thetaAll[selectedHz[i]] *= Mathf.PI;

            Hz[i] += HzAdjust;

            Debug.Log(Hz[i].ToString() + ", " + theta[i].ToString());
            //Debug.Log("key (" + i.ToString() + ")");

            key[i] = GameObject.Find("key (" + i.ToString() + ")").GetComponent<SpriteRenderer>();

            cue[i] = GameObject.Find("cue (" + i.ToString() + ")").GetComponent<SpriteRenderer>();
            cue[i].enabled = false; // disable by default

            ph[i] = GameObject.Find("ph (" + i.ToString() + ")").GetComponent<SpriteRenderer>();

            // statuses
            statusText[i] = GameObject.Find("status (" + i.ToString() + ")").GetComponent<TextMeshProUGUI>();
            statusText[i].text = "";

        }

        KEY.SetActive(false);

        if (isPhotoDiode == true)
        {
            PHOTODIODE.enabled = true;
        }
    }

    private void ConfigureTraining()
    {
        if (isTrain)
        {
            isTestingNow = false;
        }
        else if (!isTrain)
        {
            isTestingNow = true; // real-time BCI
        }

        // target matrix

        for (int i = 0; i < nBlocks; i++)
        {
            int[] tmp = RandPerm(nHz, rnd); // cue

            for (int j = 0; j < nHz; j++)
            {
                target[(i * nHz) + j] = tmp[j] - 1; // indexing from 0
                //UnityEngine.Debug.Log(target[(i * nHz) + j]);
            }
        }

    }



    // Use this for initialization
    void Start() {

        if (isVirtualPhotodiode)
        {
            isFakeSwitch = true;
        }

        Debug.unityLogger.logEnabled = isDebugging;

        SetQuality();

        ConfigureStim();
        ConfigureTraining();

        StartNetwork(isFlush);
        SendStatus(CODE.spelling);

        ChangeMatrix();
        TextLog();


        Debug.Log("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$");

        SetupPort();
    }
    
    // Update is called once per frame

    void Update () {

        KeyboardControl();

        if (!isGameStarted)
        {
            AttemptStartGame();
        }

        if (isGameStarted & !isPaused)
        {
            //InterfaceTest();
            //TestFeedback();
            ControlLoop();
        }
    }

    /////////////////////////////////////////////////////// DISPLAY CONTROL

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

    public class FrameData
    {
        public List<float> TRIAL = new List<float>();
        public List<float> FRAME = new List<float>();
        public List<float> trigger = new List<float>();
        public List<float> deltaTime = new List<float>();
        public List<float> lum = new List<float>();
        public List<float> cmFrames = new List<float>();
        public List<float> cmStimulus = new List<float>();
        public List<float> cmTrigger = new List<float>();
        public List<float> letterClassified = new List<float>();
    }

    FrameData frameData = new FrameData();

    private void ControlLoop()
    {

        if (TRIAL == -1)
        {
            InitialiseTrial();
            return;
        }

        switch (isViewingChat)
        {
            case false:

                if (FRAME == Frames.trial & !isPaused)
                {
                    InitialiseTrial();
                }

                if (FRAME < Frames.trial)
                {
                    switch (CM.stimulus[FRAME])
                    {
                        case 1: // CUE

                            if (isVirtualPhotodiode)
                            {
                                SendParallel(CM.frames[FRAME], target[TRIAL] + 1, Port.port[0]); // works if frame rate locked
                            }
                            else if (!isVirtualPhotodiode)
                            {
                                if (isTestingNow)
                                {
                                    SendParallel(CM.frames[FRAME], 29, Port.port[0]); // works if frame rate locked
                                }
                                else if (!isTestingNow)
                                {
                                    SendParallel(CM.frames[FRAME], target[TRIAL] + 1, Port.port[0]); // works if frame rate locked
                                }

                            }

                            DisplayCue();

                            /////////////////////////////////////////////// BCI

                            if (isTestingNow)
                            {
                                RealtimeFeedback();
                            }

                            break;

                        case 2: // FLICKER

                            if (isVirtualPhotodiode)
                            {
                                SendParallel(CM.frames[FRAME], target[TRIAL] + 101, Port.port[0]); // works if frame rate locked
                            }
                            else if (!isVirtualPhotodiode)
                            {
                                if (isTestingNow)
                                {
                                    SendParallel(CM.frames[FRAME], 129, Port.port[0]); // works if frame rate locked
                                }
                                else if (!isTestingNow)
                                {
                                    SendParallel(CM.frames[FRAME], target[TRIAL] + 101, Port.port[0]); // works if frame rate locked
                                }

                            }

                            DisplayFlicker();
                            break;
                    }

                    // frameData

                    frameData.TRIAL.Add((float)TRIAL); // try multi-threading the save in future
                    frameData.FRAME.Add(FRAME);
                    frameData.trigger.Add(PortAccess.Input(Port.port[0]));
                    frameData.deltaTime.Add(Time.deltaTime);
                    frameData.lum.Add(LUM);

                    frameData.cmFrames.Add((float)CM.frames[FRAME]);
                    frameData.cmStimulus.Add((float)CM.stimulus[FRAME]);
                    frameData.cmTrigger.Add((float)CM.trigger[FRAME]);

                    frameData.letterClassified.Add(letterClassified); // frameData.flipTimeStart, frameData.flipTimeStop
                    
                    FRAME++;

                    if (isTrain & TRIAL < nTrialsTrain & FRAME == 72) // 0.5 s completed, skip ahead to flicker, assumes 144 Hz
                    {
                        FRAME = 108;
                    }
                }

                break;

            case true:
                DisplayChat();
                break;
        }
    }
    
    private void DisplayCue()
    {
        if (CM.frames[FRAME] == 0)
        {

            if (isTestingNow == false | isVirtualPhotodiode == true)
            {
                cue[target[TRIAL]].enabled = true; // enable cue
            }

            LUM = 0;
        }
    }

    private void InitialiseTrial()
    {

        //Debug.Log("InitialiseTrial");

        // ready stim for cue and wait screen after train

        PHOTODIODE.enabled = false;
        PH.SetActive(true);
        CUE.SetActive(true);
        KEY.SetActive(false);

        for (int i = 0; i < nHz; i++)
        {
            cue[i].enabled = false;
            ph[i].enabled = true;
        }

        if (TRIAL == nTrialsTrain)
        {
            if (isTestingNow == false)
            {
                outputText.text = ""; // reset output text
                isTestingNow = true;
                isGameStarted = false;
            }
        }

        // advance trial

        if (isGameStarted)
        {
            letterClassified = float.NaN;

            TRIAL++;

            if (isTrain & TRIAL < nTrialsTrain)
            {
                outputText.text = (TRIAL).ToString();
            }

            FRAME = 0;
        }

        if (TRIAL == nTrials)
        {
            StartCoroutine(QuitGame()); // coroutine needed for pause
        }
    }

    private float DisplayFlicker()
    {
        if (CM.frames[FRAME] == 0)
        {
            if (isPhotoDiode == true)
            {
                PHOTODIODE.enabled = true;
            }

            PH.SetActive(false);
            KEY.SetActive(true);

            stopwatchFlicker.Reset();
            stopwatchFlicker.Start();

            flickerTime = 0;
        }

        else
        {
            flickerTime = (float)stopwatchFlicker.ElapsedMilliseconds / 1000;
        }

        for (int i = 0; i < nHz; i++)
        {
            LUM = 0.5f * (1 + Mathf.Sin(2 * Mathf.PI * Hz[i] * flickerTime + theta[i])); // construct signal
            key[i].color = new Color(LUM, LUM, LUM, 1.0f);
        }

        if (isCheckPhotoOnset == true)
        {
            LUM = 1.0f;
        }
        else
        {
            LUM = 0.5f * (1 + Mathf.Sin(2 * Mathf.PI * Hz[target[TRIAL]] * flickerTime + theta[target[TRIAL]])); // construct signal
        }

        if (isPhotoDiode == true)
        {
            PHOTODIODE.color = new Color(LUM, LUM, LUM, 1.0f);
        }

        return LUM;
    }

    /////////////////////////////////////////////////////// USER INPUT

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

    private void TestFeedback()
    {
        if (!isViewingChat)
        {
            RealtimeFeedback();
        }
        else
        {
            DisplayChat();
        }
    }

    private void RealtimeFeedback()
    {
        GetClassifiedLetter();

        if (Enumerable.Range(0, 29).Contains((int)letterClassified)) // 0 - 27 + 28
        { // 0-27 & 28 - return
            //Debug.Log("inrange");
            UpdateKeyStrokes((int)letterClassified);
        }
    }

    // records

    public class Record
    {
        public List<int> key = new List<int>(); // all key memory
        public List<string> character = new List<string>(); // working character memory
        public List<string> phrase = new List<string>(); // Record.phrase
        public List<float> characterFloat = new List<float>(); // working character memory ----- transmitted to buffer
    }

    Record record = new Record();

    public void UpdateKeyStrokes(int InpBCI) // misses last phrase
    {
        record.key.Add(InpBCI);
        //Debug.Log("InpBCI =" + InpBCI);

        if (InpBCI != CODE.backspace & InpBCI != CODE.enterKey)
        {
            record.characterFloat.Add((float)InpBCI);
            //Debug.Log("record.characterFloat[record.character.Count - 1]");
        }

        switch (InpBCI) // output window
        {

            case CODE.backspace: // BACKSPACE (-1!)

                if (outputText.text.Length > 0)
                { // check length before implementing backspace
                    record.character.RemoveAt(record.character.Count - 1); // statuses
                    record.characterFloat.RemoveAt(record.characterFloat.Count - 1); // statuses
                }
                break;

            case CODE.enterKey: // RETURN

                // send message/status

                float[,] dataToPut = new float[buffer[BID.message].nScans, buffer[BID.message].nChans];

                //Debug.Log(record.characterFloat.Count);

                for (int i = 0; i < buffer[BID.message].nChans; i++)
                {
                    //Debug.Log("i=" + i);

                    if (i < record.characterFloat.Count)
                    {
                        //Debug.Log("i=" + i + ", " + record.characterFloat[i]);
                        dataToPut[0, i] = record.characterFloat[i];
                    }
                    else
                    {
                        dataToPut[0, i] = float.NaN;
                    }
                }

                SendMessage(dataToPut);
                SendStatus(CODE.viewingChat);

                // update records
                record.phrase.Add(string.Join("", record.character.ToArray()));
                //Debug.Log("Record.phrase =" + record.phrase[record.phrase.Count - 1]);

                record.characterFloat.Clear();
                record.character.Clear(); // clear list
                outputText.text = "";

                // save phrase data
                WriteString(record.phrase[record.phrase.Count - 1] + "\n", outFilePhrases);

                letterClassified = float.NaN; // DRP HACK 16/10/2018 3:10 PM
                isViewingChat = true;
                chatStartTime = Time.time;

                // gameObjects

                BUBBLES.SetActive(true);
                PH.SetActive(false);

                if (isVirtualPhotodiode)
                {
                    CUE.SetActive(false);

                    for (int i = 0; i < nHz; i++)
                    {
                        cue[i].enabled = false;
                    }
                }

                LETTER.SetActive(false);
                STATUS.SetActive(false);
                outputText.enabled = false;
                outputWindow.SetActive(false);

                PHOTODIODE.enabled = false;

                sw.Reset();
                sw.Start();

                break;

            default:
                record.character.Add(keyAlphabet[InpBCI]); // statuses
                break;

        }

        // outputText.text = string.Join("", Record.character); // In .NET 4 you don't need the ToArray anymore, since there is an overload of String.Join that takes an IEnumerable<string>.
        outputText.text = string.Join("", record.character.ToArray());

        //Debug.Log(outputText.text);

        // statuses ----- display maximum of last three characters

        for (int i = 0; i < nHz; i++)
        {
            statusText[i].text = string.Join("", record.character.GetRange(record.character.Count - System.Math.Min(record.character.Count, 3), System.Math.Min(record.character.Count, 3)).ToArray());
        }
    }


    private void GetClassifiedLetter()
    {
        letterClassified = float.NaN;

        if ( isBufferOpen[BID.feedback] )
        {
            if ( buffer[BID.feedback].socket.connect( buffer[BID.feedback].host, buffer[BID.feedback].port ))
            {
                try
                {
                    Header hdr = buffer[BID.feedback].socket.getHeader();

                    if (hdr.nSamples > 0 & hdr.nSamples != lastReadIndex[BID.feedback])
                    {
                        float[,] data = buffer[BID.feedback].socket.getFloatData(hdr.nSamples - 1, hdr.nSamples - 1);
                        letterClassified = data[0, 0] - 1;
                        lastReadIndex[BID.feedback] = hdr.nSamples;

                        //Debug.Log(letterClassified);
                    }
                    buffer[BID.feedback].socket.disconnect();
                }
                catch (System.Net.Sockets.SocketException) { }
            }
        }
    }

    /////////////////////////////////////////////////////// MESSAGING INTERFACE

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

    float chatStartTime;
    float chatDefaultTime = 2; // for virtualPhotodiode to exit screen

    private void DisplayChat()
    {

        PortAccess.Output(Port.port[0], Trig.viewingChat); // send trigger for viewing chat

        // CheckMessages

        MessagingInterfaceIDX();

        // P2 STATUS

        switch ((int)statusR)
        {
            case CODE.spelling:
                chatIcon.SetActive(true);
                break;
            case CODE.viewingChat:
                chatIcon.SetActive(false);
                break;
            default:
                chatIcon.SetActive(false);
                break;
        }

        // end chat

        if (isFakeSwitch) // for testing - set automatically to true if isVirtualPhotodiode
        {
            if (Time.time - chatStartTime > chatDefaultTime)
            {
                isViewingChat = false;
            }
        }
        else if (!isVirtualPhotodiode)
        {
            GetClassifiedLetter();

            if (letterClassified == CODE.enterKey) // enter artifact key
            {
                isViewingChat = false;
            }
        }

        // clean up

        if (isViewingChat == false)
        {

            Debug.Log("sw " + sw.ElapsedMilliseconds);
            PortAccess.Output(Port.port[0], 0); // try to reset port

            if (isPhotoDiode == true)
            {
                PHOTODIODE.enabled = true;
            }

            // GameObjects

            if (isVirtualPhotodiode)
            {
                CUE.SetActive(true);
            }

            BUBBLES.SetActive(false);
            PH.SetActive(true);
            LETTER.SetActive(true);
            STATUS.SetActive(true);
            outputText.enabled = true;
            outputWindow.SetActive(true);

            chatIcon.SetActive(false);
            letterClassified = float.NaN; // reset nSamples to avoid picking up noise trigger on the way out, and getting things out of alignment

            SendStatus(CODE.spelling);
            FRAME = Frames.trial; // advance to next trial - 28/10/2018 9:59 PM

        }
    }


    static int nPlayers = 2;
    string[] strPlayer = { "P1", "P2" };

    List<string> messageLog = new List<string>() { };

    private void MessagingInterfaceIDX()
    {
        for (int PLAYER = nPlayers; PLAYER-- > 0;) // count backwards
        {
            int idx;
            switch (PLAYER)
            {
                case 0:
                    idx = BID.message;
                    break;
                case 1:
                    idx = BID.messageR;
                    break;
                default: // -2147483648 if float.nan
                    idx = BID.message;
                    break;
            }
            //Debug.Log("idx = " + idx.ToString());
            if ( isBufferOpen[buffer[idx].i] )
            {
                //Debug.Log(strPlayer[PLAYER]);

                if ( buffer[idx].socket.connect( buffer[idx].host, buffer[idx].port ) )
                {
                    try
                    {
                        Header hdr = buffer[idx].socket.getHeader();

                        if (lastReadIndex[buffer[idx].i] == hdr.nSamples | hdr.nSamples == 0 )
                        {
                            continue;
                        }

                        //Debug.Log("*" + lastReadIndex[buffer[idx].i]);
                        //Debug.Log(hdr.nSamples);

                        for (int i = lastReadIndex[buffer[idx].i]; i < hdr.nSamples; i++)
                        {
                            //Debug.Log("*" + i.ToString());

                            string message = ReceiveMessageIDX2(buffer[idx], new int[2] { i, i }); //Debug.Log(message); // check local

                            //Debug.Log("*" + message);

                            if (message != "")
                            {
                                message = strPlayer[PLAYER] + ": " + message;
                                messageLog.Add(message);

                                SpawnBubbles(PLAYER); // PLAYER

                                using (StreamWriter sr = new StreamWriter(outFileChatLog, append: true))
                                {
                                    message = System.DateTime.Now.ToString("yy.MM.dd.HH.mm.ss.fffffff") + ": " + message + "\n";
                                    sr.Write(message);
                                    Debug.Log(message);

                                }
                            }
                        }

                        lastReadIndex[buffer[idx].i] = hdr.nSamples;
                        buffer[idx].socket.disconnect();
                    }
                    catch (System.Net.Sockets.SocketException) { }
                }
            }
        }

        if (isBufferOpen[buffer[BID.statusR].i])
        {
            statusR = GetStatus(buffer[BID.statusR]); // Debug.Log(statusR);
        }

    }

    // SPAWN BUBBLES

    public GameObject[] ChatText = new GameObject[nPlayers];
    List<GameObject> spawnedChat = new List<GameObject>() { };
    List<TextMeshProUGUI> spawnedChatTxt = new List<TextMeshProUGUI>() { };
    List<int> nLines = new List<int>() { };
    public List<bool> isDestroyed = new List<bool>() { };

    private void SpawnBubbles(int PLAYER)
    {

        int counter = messageLog.Count - 1;

        spawnedChat.Add(Instantiate(ChatText[PLAYER], Vector3.zero, Quaternion.identity) as GameObject);
        spawnedChatTxt.Add(spawnedChat[counter].GetComponentInChildren<TextMeshProUGUI>());
        spawnedChatTxt[counter].text = messageLog[counter];

        spawnedChat[counter].transform.SetParent(BUBBLES.transform);

        isDestroyed.Add(false);

        // scroll

        float[] heights = { 78.79f, 142.54f, 206.29f, 270.03f, 333.78f, 397.53f }; // rectTransform.height

        if (spawnedChatTxt[counter].text.Length <= 31) // cannot know height or number of lines until next frame :,( took me hours to debug - could also wait until next frame to draw, but that would be too easy
        {
            nLines.Add(0);
        }
        else if (spawnedChatTxt[counter].text.Length <= 62)
        {
            nLines.Add(1);
        }
        else if (spawnedChatTxt[counter].text.Length <= 93)
        {
            nLines.Add(2);
        }
        else if (spawnedChatTxt[counter].text.Length <= 124)
        {
            nLines.Add(3);
        }
        else if (spawnedChatTxt[counter].text.Length <= 155)
        {
            nLines.Add(4);
        }
        else if (spawnedChatTxt[counter].text.Length <= 186)
        {
            nLines.Add(5);
        }

        Vector3 pos1 = spawnedChatTxt[counter].transform.position; // baseline correction
        pos1.y = pos1.y + heights[nLines[counter]] / 2;
        spawnedChatTxt[counter].transform.position = pos1;

        if (counter >= 1)
        {

            //float shift = heights[nLines[msgCount - 1]]/2 + heights[nLines[msgCount - 2]]/2; // if not baseline correction
            float shift = heights[nLines[counter]]; // baseline correction

            for (int i = 0; i < counter; i++)
            {
                if (isDestroyed[i] == false) // spawnedChatTxt[i].IsActive() )
                {
                    Vector3 pos = spawnedChatTxt[i].transform.position;
                    pos.y = pos.y + shift;
                    spawnedChatTxt[i].transform.position = pos;
                }

            }
        }

        // clean up additional bubbles

        int lastToDraw = counter - 13;

        if (lastToDraw < 0)
        {
            lastToDraw = 0;
        }

        //for (int i = lastToDraw; i < counter; i++)
        //{
        //    spawnedChat[i].SetActive(true);
        //}

        for (int i = 0; i < lastToDraw; i++)
        {
            if (isDestroyed[i] == false)
            {
                Destroy(spawnedChat[i]);
                isDestroyed[i] = true;
            }
        }

    }

    float messageRate = .5f;
    float nextMessage = 0f;

    private void InterfaceTest()
    {

        if (Time.time > nextMessage)
        {

            float[,] message = CreateRandomMessage();
            SendMessage(message);
            nextMessage = Time.time + messageRate;

        }

        MessagingInterfaceIDX();
    }

    private void LocalBufferTest()
    {
        if (isBufferOpen[BID.feedback])
        {
            float status = GetStatus(buffer[BID.feedback]);
            Debug.Log(status);
        }

        if (isBufferOpen[BID.status])
        {
            SendStatus(Time.deltaTime);
            float status = GetStatus(buffer[BID.status]); Debug.Log(status);
        }

        if (isBufferOpen[BID.message])
        {
                float[,] message = CreateRandomMessage();
                SendMessage(message);
                string messageS = ReceiveMessageLast(buffer[BID.message]); Debug.Log(messageS);
        }
    }

    /////////////////////////////////////////////////////// MISC. METHODS

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

    private void SendParallel(int FRAME, int TRIGGER, int ADDRESS)
    {
        if (FRAME <= Frames.trigger)
        {
            PortAccess.Output(ADDRESS, TRIGGER);
        }
        else
        {
            PortAccess.Output(ADDRESS, 0);
        }
    }

    private void AttemptStartGame()
    {
        if (isTestingNow)
        {
            if (!isTrain)
            {
                isGameStarted = true;
            }
            else
            {
                if (isBufferOpen[BID.feedback])
                {
                    float status = GetStatus(buffer[BID.feedback]);

                    if (status == CODE.train | status == CODE.test)
                    {
                        isGameStarted = true;
                    }
                }
            }
        }
        else
        {
            if (Time.frameCount <= Frames.startPause)
            {
                SendParallel(Time.frameCount, Trig.startRecording, Port.port[0]);
            }
            else
            {
                if (isWaitMatlab)
                {
                    if (isBufferOpen[BID.feedback])
                    {
                        float status = GetStatus(buffer[BID.feedback]);

                        if (status == CODE.train | status == CODE.test)
                        {
                            isGameStarted = true;
                        }
                    }   
                }
                else
                {
                    isGameStarted = true;
                }
            }
        }
    }

    private void OnApplicationQuit()
    {
        StartCoroutine(QuitGame());
    }

    public System.Collections.IEnumerator QuitGame()
    {
        Debug.Log("quitting");

        if (isStopRecording)
        {
            PortAccess.Output(Port.port[0], Trig.stopRecording);
        }

        // write frameData

        float[,] dataToPut = new float[frameData.TRIAL.Count, 9]; // messes with frame rate - so put outside main frame loop

        for (int i = 0; i < frameData.TRIAL.Count; i++)
        {
            dataToPut[i, 0] = frameData.TRIAL[i];
            dataToPut[i, 1] = frameData.FRAME[i];
            dataToPut[i, 2] = frameData.trigger[i];
            dataToPut[i, 3] = frameData.deltaTime[i];
            dataToPut[i, 4] = frameData.lum[i];
            dataToPut[i, 5] = frameData.cmFrames[i];
            dataToPut[i, 6] = frameData.cmStimulus[i];
            dataToPut[i, 7] = frameData.cmTrigger[i];
            dataToPut[i, 8] = frameData.letterClassified[i];
        }

        Write2D(dataToPut, outFileFD, "");

#if UNITY_EDITOR
        // Application.Quit() does not work in the editor so
        // UnityEditor.EditorApplication.isPlaying need to be set to false to end the game
        UnityEditor.EditorApplication.isPlaying = false;
#else
            Application.Quit();
#endif

        yield return new WaitForSeconds(0.1f); // to ensure trigger is sent, probably not necessary

    }


    public void KeyboardControl()
    {

        if (Input.GetKeyDown(KeyCode.P))
        {
            if (!isPaused)
            {
                isPaused = true;
            }
            else
            {
                isPaused = false;
            }
        }
        else if (Input.GetKeyDown(KeyCode.Escape))
        {
            StartCoroutine(QuitGame());
        }
    }

}
