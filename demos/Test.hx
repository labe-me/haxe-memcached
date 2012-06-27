import memcached.Connection;

class MyClass {
	public var id : Int;
	public var data : String;

	public function new( id:Int, data:String ){
		this.id = id;
		this.data = data;
	}
}

class Test {

	static var SOME_DATA = "Foo bar baz biz buz";
	static var MORE_DATA = "Lorem ipsum doloris";

	static function test( label:String, expect:Dynamic, result:Dynamic, ?pos:haxe.PosInfos ){
		if (expect != result)
			neko.Lib.println("(line "+pos.lineNumber+") Test "+label+" => test failed");
		else
			neko.Lib.println("(line "+pos.lineNumber+") Test "+label+" => ok");
	}

	static function testClient(){
		var client = new memcached.Client("localhost", 11211);
		test("flushAll()", true, client.flushAll());
		test("get() null", null, client.get("foo"));
		test("set()", true, client.add("foo", SOME_DATA));
		test("set() worked", SOME_DATA, client.get("foo"));
		test("add() fails after set()", false, client.add("foo", MORE_DATA));
		test("replace()", true, client.replace("foo", MORE_DATA));
		test("replace() really works", MORE_DATA, client.get("foo"));
		test("set() acts as replace", true, client.set("foo", SOME_DATA));
		test("set() really acted as replace", SOME_DATA, client.get("foo"));
		test("delete()", true, client.delete("foo"));
		test("delete() really worked", null, client.get("foo"));
		test("set() with expires in 2 seconds", true, client.set("foo", SOME_DATA, 2));
		test("set() works again", SOME_DATA, client.get("foo"));
		neko.Sys.sleep(2.5);
		test("set() expires really worked", null, client.get("foo"));
		test("set(String)", true, client.set("bar", "some value"));
		test("set(String) really worked", "some value", client.get("bar"));
		var object : MyClass = client.get("my_object");
		if (object == null){
			object = new MyClass(10, "youhou");
			client.set("my_object", object);
		}
		var after : MyClass = client.get("my_object");
		test("object serialization", after != null, true);
		test("object serialization id", after.id, object.id);
		test("object serialization data", after.data, object.data);
		client.close();
		test("flushAll() when disconnected", false, client.flushAll());
		test("get() when disconnected", null, client.get("bar"));
	}

	static function testConnection(){
	}

	public static function main(){	
		testClient();
		testConnection();
	}
}
