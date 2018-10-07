# Bugs to fix



# Improvement to do

- Unify debugging print
- Add file system monitor to filebrowser
- Update software structure diagram
- Write a formal README.md file




<!--#  To Do-->
<!---->
<!--## CSXFileBrowser-->
<!---->
<!--- Complete the implement of FileBrowserMenu.-->
<!--- Complete the implement of file access: open file and save file.-->
<!--    - If the file cannot be opened as text file, open it as binary and dump as hex.-->
<!--    - If the file cannot be opened as text file, all attemptions of modifying the file content should be discarded.-->
<!---->
<!--## CSXTabViewController-->
<!---->
<!--Test the compatibility with ACE editor-->
<!---->
<!--## ACEViewSwift-->
<!---->
<!--Test the compatibility with ACE editor-->
<!---->
<!--## CSXCodeEditor-->
<!---->
<!--Combine CSXTabViewController with ACEViewSwift-->
<!---->
<!--## CSXCompiler-->
<!---->
<!--This is a framework acting like a make system. It should support the following functions:-->
<!--- invoke gcc, linker(ld), converter and library archiver(ar).-->
<!--- analyse the output and throw proper errors to indicate what had happened.-->
<!---->
<!--## CSXLibraryManager-->
<!---->
<!--This is a framework for managing c libraries. It should support the following functions:-->
<!--- record the name, author, version, description, categories, header file to include, dependencies and so on.-->
<!--- create user's own library package-->
<!--- update user's libraries if there is a newer version-->
<!--    -->
<!--## CSXProjectManager-->
<!---->
<!--This is a framework providing support of cmsproj file. All modifications of a project will be sent to this framework.-->
<!--Note: make a single shared manager and manage all projects!-->
<!--Check the configuration and make sure it doesn't conflict with the existant files!-->
<!---->
<!--### Design a new project structure!-->
<!--|: ----------------------------------------- :|-->
<!--|                   Project Folder                   |-->
<!--|-------------------------------------------|-->
<!--| cmsproj file |    Source code folder    |-->
<!--| .config.json |  .c files .h files cms file  |-->
<!---->
<!--### Design a new temp project folder structure!-->
<!--|-------------------------------------------|-->
<!--|          Temporary Project Folder          |-->
<!--|-------------------------------------------|-->
<!--|            release        |             lib           |-->
<!--|-------------------------------------------|-->
<!---->
<!--## SerialKit-->
<!---->
<!--This is a framework for serial communication. It is a improved version based on ORSSerialPort.-->
<!---->
<!--## CSXSerialConsole-->
<!---->
<!--This is a framework for uploading binary to the chip, receiveing data from the chip-->
<!---->
<!--## CSXDataAnalyzer-->
<!---->
<!--This is a framework providing basic data analysis.-->
<!---->
<!--## CSXCompilerInstaller-->
<!---->
<!--This is a framework used to install mips cross compiler toolchains when necessary.-->
<!---->
<!--## CSXDriverInstaller-->
<!---->
<!--This is a framework used to install serial drivers when necessary.-->
<!---->
<!--|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-->
<!--|                                       CamelStudio                                     |-->
<!--|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-->
<!--|                     CSXProjectManager                  |     CSXFileBrowser     |                    CSXCodeEditor                  |      CSXSerialConsole     | CSXDataAnalyzer |-->
<!--| cmsproj Parser | cms Parser | CSXCompiler |  CSXFileTreeManager | CSXTabViewController | ACEViewSwift | SerialKit | CSXUploader |         PlotKit           |-->
<!--            ^-->
<!--             |-->
<!--             |-->
<!--|    Document      |-->
<!---->
<!---->
<!--|                  Version Management                |-->
<!--| Sparkle |         CSXLibraryManager         |-->
<!--|              | SwiftDownloader | cmslib Parser |-->
<!---->
<!---->
<!--|              CSXEnvironmentCheck                |-->
<!--| CSXCompilerInstaller | CSXDriverInstaller |-->
