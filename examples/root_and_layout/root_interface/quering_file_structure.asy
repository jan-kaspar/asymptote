string list[];

// this prints the list of sub-directories and objects in the root directory of the file
list = RootGetListOfEntries("../example.root", "/");
write("1) ", list);

// this prints the list of sub-directories (only!) in the root directory of the file
list = RootGetListOfDirectories("../example.root", "/");
write("2) ", list);

// this prints the list of objects in the directory called `dir'
list = RootGetListOfObjects("../example.root", "dir1");
write("3) ", list);
