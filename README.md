> [!IMPORTANT]  
> This menace is now identified as "Trojan:PowerShell/TommyTech.C". There is quite probably no need for you to use this script as Windows Defender will take care of it. Whatever you have, it might not be this specific branch of the virus.

# YourSearchBar.me Removal Tool

This PowerShell script is designed to hopefully **remove the *yoursearchbar.me*** extension malware from your Windows computer.

I tested it on a few computers (running Windows 11) that were infected with the 9.8 version of the malware, and it worked, *but I cannot guarantee that it will work for you*.

## How to Use the Removal Tool

Please follow these steps carefully to use the removal tool:

### Step 1: Download the Tool

> You must either clone this repository (required git and git-lfs installed on your system) or download the ZIP file (the script will have to download the large files itself). Here's how to easily download the ZIP file:

1. Click on the green **"Code"** button on this GitHub repository page.
2. Click on **"Download ZIP"** from the dropdown menu.
3. Save the ZIP file to your computer.
4. Right-click on the downloaded ZIP file and select **"Extract All..."**.
5. Choose a location to extract the files and click **"Extract"**.

### Step 2: Run the Tool

> If none of the two options below work, you may need to disable your antivirus software temporarily.

#### Solution 1
1. After extracting the files, navigate to the folder where you extracted them.
2. Find the file named `removal.ps1`.
3. Right-click on `removal.ps1` and select "Run with PowerShell". 

#### Solution 2
If this script doesn't open or close immediately, you may need to run it from a terminal:
1. Open a PowerShell console with administrative rights. Search for **"PowerShell"** in the Start Menu, right-click on **"Windows PowerShell"** and select ***"Run as administrator"***.
2. Navigate to the folder where you extracted the files. To do so, copy the path in the Windows Explorer address bar and type `cd <path>` in the terminal, replacing `<path>` with the path you copied.
3. You should now be in the folder where you extracted the files. If you are not, please double-check the path you copied and try again.
4. Type `powershell -ExecutionPolicy Bypass -File removal.ps1` and hit Enter.

If you see a PowerShell console window open, the script is now running. 
The script will then tell you what it is doing and will ask for your confirmation to continue.

### Important Notes

- You may need to confirm that you want to run the script with administrative privileges (UAC). Click "Yes" if prompted.
- It is possible that Microsoft Edge doesn't work after the script completes. If this happens, please try to [repair your installation](https://support.microsoft.com/en-us/microsoft-edge/what-to-do-if-microsoft-edge-isn-t-working-cc0657a6-acd2-cbbd-1528-c0335c71312a).
- When downloading the script following the instructions above ("Download ZIP" button), it won't download the three `.dll` files because of GitHub limitations with big files. Therefore, the script will download it itself at runtime, don't worry if it takes a while, it essentially depends on your internet connection.
- After the script completes, please restart your computer to ensure all changes take effect.
- If the malware is still present after the script completes, it is possible that you installed a software on your computer that ensure the malware is reinstalled. Please check your installed programs and remove any suspicious software.

## Need Help?

If you encounter any issues or need further assistance, please [create an issue](https://github.com/E-B3rry/yoursearchbar.me-removal/issues) on this GitHub repository.
You can also email me at [julesreixcharat@gmail.com](mailto:julesreixcharat@gmail.com?subject=Issue%20or%20request%20concerning%20yoursearchbar.me-removal).
