# 🔍 SharpExclusionFinder

[![PowerShell](https://img.shields.io/badge/PowerShell-v5%2B-blue)](https://docs.microsoft.com/powershell) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**SharpExclusionFinder** is a PowerShell tool illustrating a Windows Defender vulnerability: even **low-privilege** (non-administrative) users can brute‑force Defender exclusion settings to discover ignored directories. This interactive scanner enumerates excluded folders across all drives or within a specific directory. 🚀

> ⚠️ **Disclaimer:**
> - This tool is for **educational & authorized testing only**. Do **not** use without explicit permission.
> - Misuse may violate policies or laws. The author is **not** liable for damages or legal issues. 🙅‍♂️

## ✨ Features

- ✅ Interactive menu-driven interface
- 🌐 Scan **all drives** or a **specific folder** (with optional subfolders)
- 📊 Verbosity levels:
  - **0**: Summary only
  - **1**: List exclusions as found
  - **2**: Full scan activity logs
- 🛑 Option to stop on first exclusion found
- 📝 Save results to an output file

## 📋 Requirements

- Windows 10 / Windows Server 2016+
- PowerShell **v5.1** or above
- **Standard user** (no elevated/admin privileges required)
- `MpCmdRun.exe` at `%ProgramFiles%\Windows Defender\MpCmdRun.exe`

## 📥 Installation

1. Clone or download this repo:
   ```powershell
   git clone https://github.com/<your-org>/SharpExclusionFinder.git
   ```
2. Change directory:
   ```powershell
   cd SharpExclusionFinder
   ```
3. (Optional) Unblock script if needed:
   ```powershell
   Unblock-File .\SharpExclusionFinder.ps1
   ```

## 🚀 Usage

Run in a PowerShell session with **standard user privileges**:

```powershell
.\SharpExclusionFinder.ps1
```

1. **Select** scan option:
   - **1**: All drives 💽
   - **2**: Specific folder 📁
   - **Q**: Quit ❌
2. **Choose** verbosity (0, 1, 2)
3. **Decide** to stop on first exclusion (Y/N)
4. **Specify** output file (or leave blank)
5. **For option 2**: enter target folder and subfolder inclusion (Y/N)

### 💡 Example

```powershell
.\SharpExclusionFinder.ps1
# 2 → Specific folder
# Verbosity: 1
# Stop on first: N
# Output file: exclusions.txt
# Folder: C:\Projects
# Include subfolders: Y
```

Results will display excluded directories and optionally write to `exclusions.txt`. 💾

## 🛠️ How It Works

1. Uses `Get-PSDrive` to list drives.
2. Recursively gathers subfolders with `Get-ChildItem -Directory -Recurse`.
3. Invokes Defender scan:
   ```powershell
   MpCmdRun.exe -Scan -ScanType 3 -File "<Folder>\|*"
   ```
4. Parses output for `was skipped` → indicates exclusion.

## 🛡️ Mitigation & Recommendations

- 🔍 Regularly audit exclusions via Group Policy or `Get-MpPreference`.
- 🔐 Enforce **least privilege** and restrict access to Defender settings.
- 📈 Monitor `MpCmdRun` in Event Logs for abnormal use.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Open an issue or pull request on GitHub. 🏗️

## 📄 License

This project is licensed under the [MIT License](LICENSE). 🎉

