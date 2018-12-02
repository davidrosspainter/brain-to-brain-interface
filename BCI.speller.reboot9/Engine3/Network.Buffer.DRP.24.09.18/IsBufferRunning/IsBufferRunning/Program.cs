using System;
using System.Diagnostics;

namespace IsBufferRunning
{

    class Program
    {

        // matlab syntax: [~,result] = system('ConsoleApp1.exe localhost 1' ) or [~,result] = system('ConsoleApp1.exe' )

        static void Main(string[] args)
        {

            //Console.WriteLine("Hello World!");

            string host = "";
            string port = "";


            if (args.Length == 0)
            {
                host = "127.0.0.1";
                port = "1111";
            }
            else
            {
                host = args[0]; //Console.WriteLine(host);
                port = args[1]; //Console.WriteLine(port);
            }

            Console.WriteLine( IsBufferRunningX(host, port) );
            //Console.ReadKey(); // Keep the console window open in debug mode unit key press
            
        }

        public static bool IsBufferRunningX(string host, string port)
        {

            string targetWindowName = "C:\\Windows\\System32\\cmd.exe - buffer.exe  " + host + " " + port + " -";
            bool targetFound = false;

            System.Diagnostics.Process[] processlist = System.Diagnostics.Process.GetProcessesByName("cmd"); // ("buffer");

            foreach (System.Diagnostics.Process process in processlist)
            {
                if (!System.String.IsNullOrEmpty(process.MainWindowTitle))
                {
                    if (process.MainWindowTitle.ToLower() == targetWindowName.ToLower())
                    {
                        targetFound = true;
                        break;
                    }
                }
            }

            return targetFound;

        }
    }
}

