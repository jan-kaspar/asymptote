string list[];

// this prints the list of sub-directories and objects in the root directory of the file
list = rGetListOfEntries("../example.root", ".");
write("1) ", list);

// this prints the list of sub-directories (only!) in the root directory of the file
list = rGetListOfDirectories("../example.root", ".");
write("2) ", list);

// this prints the list of objects in the directory called `dir'
list = rGetListOfObjects("../example.root", "dir1");
write("3) ", list);
