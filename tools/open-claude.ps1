# Script to open WordPress_Dev WSL and navigate to TubeScribe directory with Claude auto-launch
function Open-TubeScribe {
   # WSL Instance Configuration
   # WordPress_Dev = Our WSL 2 Ubuntu instance name
   # Change this if the WSL instance name ever changes
   
   # Claude Path Explanation:
   # Claude is installed locally (not system-wide) and configured as an alias in ~/.bashrc
   # The alias points to: /home/hefin/.claude/local/claude
   # 
   # WHY WE USE FULL PATH INSTEAD OF 'claude' COMMAND:
   # - Aliases only work in INTERACTIVE shells (when you open WSL normally)
   # - PowerShell WSL commands use NON-INTERACTIVE shells
   # - Non-interactive shells don't load ~/.bashrc, so the alias isn't available
   # - Therefore we must use the full executable path that the alias points to
   #
   # TO UPDATE IN FUTURE:
   # 1. Open WSL terminal normally
   # 2. Run: type claude
   # 3. Copy the path it shows after "claude is aliased to"
   # 4. Update the path below
   
   # Define the WSL command using the actual claude executable path
   $wslCommand = "wsl -d WordPress_Dev -e bash -c 'cd /mnt/c/tools/TubeScribe && /home/hefin/.claude/local/claude --add-dir /mnt/c/Users/hsank/Documents/ShareX/Screenshots'" 

   # Start a new PowerShell window with the WSL command
   # -NoExit keeps the window open so you can see Claude running
   # Use full path to wt.exe
   $wtPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
   & $wtPath -w 0 new-tab --title "CLAUDE CODE - TUBESCRIBE" --tabColor "#002B36" pwsh.exe -NoExit -Command $wslCommand

   # Alternatively, if you want to use PowerShell directly without Windows Terminal:
      # Start-Process pwsh.exe -ArgumentList "-NoExit", "-Command", $wslCommand
}

# Execute the function
Open-TubeScribe