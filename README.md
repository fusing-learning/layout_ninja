# **Layout Ninja - A macOS Window Manager**

A simple, command-line tool for macOS to save and restore the position and size of your application windows. Perfect for developers, designers, or anyone who wants to quickly switch between different window layouts for various tasks (e.g., "work mode," "presentation mode").

## **Features**

* **Save Layout:** Captures the position and size of all open application windows.  
* **Restore Layout:** Resets windows to their previously saved positions and sizes.  
* **Multiple Profiles:** Save and restore different layouts by specifying unique filenames.  
* **Lightweight:** A single Swift script with no external dependencies.

## **Requirements**

* macOS  
* Swift Compiler (included with Xcode Command Line Tools)

## **Installation & Setup**

1. **Clone or Download:** Get the main.swift file from this repository.  
2. **Compile the Tool:** Open your Terminal, navigate to the directory where you saved main.swift, and run the Swift compiler:  
   swiftc main.swift \-o window-manager

   This command compiles the code and creates an executable file named window-manager in the same directory.  
3. **(Optional) Move to a Global Path:** For easy access from anywhere in your terminal, move the compiled executable to a directory in your system's PATH. A common choice is /usr/local/bin:  
   mv window-manager /usr/local/bin/

## **⚠️ Important: Granting Permissions**

This tool requires **Accessibility** permissions to control application windows. The first time you run it, you will be prompted to grant these permissions.

1. Run the tool once (e.g., window-manager save). It will likely fail but will register itself with the system.  
2. Go to **System Settings** \> **Privacy & Security** \> **Accessibility**.  
3. Find window-manager (or your terminal application, like Terminal / iTerm / Warp) in the list and enable it by toggling the switch.

You only need to do this once.

## **Usage**

The tool has two main commands: save and restore. You can optionally provide a filename to manage different layouts. If no filename is provided, it defaults to window\_positions.json.

#### **Save a Layout**

* **Save to the default file:**  
  window-manager save

* **Save to a custom file (e.g., for a "work" setup):**  
  window-manager save work-layout.json

#### **Restore a Layout**

* **Restore from the default file:**  
  window-manager restore

* **Restore from a custom file:**  
  window-manager restore work-layout.json

## **How It Works**

The tool uses the macOS **Accessibility API** (ApplicationServices) to query running applications and get a list of their open windows. For each window, it retrieves its title, position, and size. This information is encoded into a JSON file for storage. The restore command reads this JSON file and uses the same API to set the position and size of the corresponding windows.
