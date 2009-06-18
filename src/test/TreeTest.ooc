import gtk.Gtk;
import gtk.Button;
import gtk.Window;
import gtk.TreeView;
import gtk.TreeViewColumn;
import gtk.TreeStore;
import gtk.TreeNode;
import gtk.VBox;

enum Column {
	COL_TITLE,
	COL_DESC,
	NUM_COLS,
}

func main(Int argc, String[] argv) {
	
	Gtk.init(&argc, &argv);
	
	Window window = new Window("Rock Tree Test");
	window.setUSize(640, 480);
	window.connectNaked("delete_event", Gtk.@mainQuit);
	
	Int[] types = {
		G_TYPE_STRING,
		G_TYPE_STRING,
	};
	
	TreeStore store = new(NUM_COLS, types);
	
	TreeNode root1 = new(store);
	root1.setValue(COL_TITLE, "root1");
	root1.setValue(COL_DESC, "First root node");
	
	TreeNode root2 = new(store);
	root2.setValue(COL_TITLE, "root2");
	root2.setValue(COL_DESC, "Second root node");
	
	TreeNode child1 = new(store, root2);
	child1.setValue(COL_TITLE, "child1");
	child1.setValue(COL_DESC, "First Child node");
	
	TreeNode grandChild1 = new(store, child1);
	grandChild1.setValue(COL_TITLE, "grandChild1");
	grandChild1.setValue(COL_DESC, "First Grand Child node");
	
	TreeView treeView = new(store);
	treeView.appendColumn(new TreeViewColumn("Title", COL_TITLE));
	treeView.appendColumn(new TreeViewColumn("Description", COL_DESC));
	
	VBox vbox = new(false, 5);
	window.add(vbox);
	
	vbox.packStart(Button.newTextButton("Is there something under here?"));
	vbox.packStart(treeView);
	vbox.packStart(Button.newTextButton("Is there something over here?"));
	
	window.showAll;
	
	Gtk.main;
	
}
