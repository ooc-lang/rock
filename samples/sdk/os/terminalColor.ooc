import os/Terminal

main: func {
	
	Terminal setFgColor(Color red);
	printf("Beautiful in red, isn't it?\n");
	Terminal setAttr(Attr bright);
	printf("YOU MUST READ THIS IN BRIGHT\n");
	Terminal setBgColor(Color green);
	printf("EEEEWWWWW, red on green...\n");
	Terminal setColor(Color blue,Color black);
	printf("i like blue =) \n");
	Terminal reset();
	printf("And back to normal!\n");
}
