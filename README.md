# DavinciImportMembers
Imports youtube members .csv files into davinci resolve with ton of customization and formatting options 
  
  
**Installation**  
Yada yada, pop the script into `%appdata%/Blackmagic Design/DaVinci Resolve/Support/Fusion/Scripts/Edit/`  
and it can be found inside davinci resolve at `Workspace>Scripts>ImportMembers`

## Settings
These can be accessed at the top of the .lua script file

- FolderOpenPath (String)  
  What folder to start in when choosing a CSV file, Probably would want it to be your downloads folder for use of ease  
  Default: `os.getenv('APPDATA')..[[/Blackmagic Design/DaVinci Resolve/]]`  

- ScriptPath (String)  
  This path should be where this script is located at. This is used when opening the script via it's gui. Useful when editing options  
  Default: `os.getenv('APPDATA')..[[/Blackmagic Design/DaVinci Resolve/Support/Fusion/Scripts/Edit/ImportMembers.lua]]`

- DisplayedMemberTeirs (Table, String)  
  Decides what member teirs will be shown with a prefix inside of hard brackets before their name  
  Default: `{}`  

- Resolution (Table, Number)  
  X,Y Screen Resolution, The Clipboard window will appear near the center of your screen with correct input  
  Leaving this as an empty table will make the script auto-get the current resolution via powershell.  
  Default: `{1920, 1080}`   

- MemberTeirs (Table, String)  
  You can specify your own members but it will look for the teirs automatically.  
  You can override that if you fill this in.  
  (Order may be weird in the auto one, specify the teirs if you want a specific order in the drop-down)  
  Default: `{}` 

- NonTeirGap (String)  
  Decides what string will be placed if the teir doesnt match in the teir specific clipboards  
  Default: `"\n"`  

- GlobalPrefix (String)  
  Will add a specific prefix on all member names (Goes before Teir Prefix)  
  Default: `""`
  
- GlobalSuffix (String)  
  Will add a specific suffix on all member names (Goes before Teir Suffix)  
  Default: `""`  


- TeirPrefix (Table, String)  
  Will add a specific prefix depending on the teir (Goes after Teir Prefix)  
  ["TeirName"] = "Prefix"  
  Default: `{}`  
  
- TeirSuffix (Table, String) 
  Will add a specific suffix depending on the teir (Goes after Teir Suffix)  
  ["TeirName"] = "Suffix"  
  Default: `{}` 

- TeirDisplayPrefix (String)  
  Decides on what characters it will put before the teir if the specified teir is in "DisplayedMemberTeirs"  
  Default: `"["`
  
- TeirDisplaySuffix (String)  
  Decides on what characters it will put after the teir if the specified teir is in "DisplayedMemberTeirs"  
  Default: `"] "`
