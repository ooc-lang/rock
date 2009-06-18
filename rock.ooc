include stdio;
import structs.ArrayList;
import lang.String;

func main(Int argc, String[] argv) {

	if(argc <= 1) {
		printf("rock: no files\n");
		exit(1);
	}

	ArrayList unitList = new;

	for(Int i: 1..argc) {
		String arg = argv[i];
		if(arg.startsWith("-")) {
			printf("Option: '%s'\n", arg);
		} else {
			unitList.add(arg);
			printf("File to compile: '%s'\n", arg);
		}
	}

}
