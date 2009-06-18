import structs.Array;
import structs.Iterator;

func main(Int argc, String[] argv) {
	
	Array args = new Array(argc, argv);
	
	printf("Args: ");
	
	String arg;
	Iterator i = args.iterator;
	while(i.hasNext) {
		arg = i.next;
		if(i.hasNext) {
			printf("\"%s\", ", arg);
		} else {
			printf("\"%s\"", arg);
		}
	}
	printf("\nDisappearing..\n");
	
	return 0;
	
}
