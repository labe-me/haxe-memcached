/*
 * Copyright (c) 2008, Motion-Twin
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY MOTION-TWIN "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */

package memcached;

// temporary import, fix haxe 2.0 missing Type information, nicolas will re-add 
// this to neko/Boot.hx soon
import Type;

/**

	If no memcached server is available, no exception is thrown by this Client, 
	please ensure that your code logic supports it :)

	Simple Usage:

		// may be a static shared accross apache processes
		var cache = new memcached.Client(host, port);

		// usual way of retrieving a cached object
		var object : MyClass = client.get("my_object_key");
		if (object == null){
			object = new MyClass();
			object.data = "foo bar baz";
			cache.set("my_object_key", object);
		}

		// deleting an object
		cache.delete("my_object_key");
		
		// setting an expire time in seconds
		cache.set("my_object_key", object, 10);

		// flushing the entire memcached memory
		cache.flushAll();

		// might be necessary (or not)
		cache.close();

	See memcached.Connection for more information about the protocol and the
	way this class works.

**/
class Client {

	private var cnx : Connection;

	// use neko.Lib.serialize and neko.Lib.localUnserialize by default but
	// you may prefer to use haxe.Serializer.run and haxe.Unserializer.run
	// or anything else like json to communicate with other applications
	public var serialize : Dynamic -> String;
	public var unserialize : String -> Dynamic;
	public var timeout : Float;

	public function new( ?host:String, ?port:Int ){
		timeout = 5.0;
		if (host != null)
			connect(host, if (port == null) 11211 else port);
		serialize = neko.Lib.serialize;
		unserialize = neko.Lib.localUnserialize;
	}
	
	public function connect( host:String, port:Int ){
		if (cnx != null)
			close();
		try {
			cnx = new Connection();
			cnx.setTimeout(timeout);
			cnx.connect(host, port);
		}
		catch (e:Dynamic){
			cnx = null;
		}
	}

	public function close(){
		if (cnx != null){
			cnx.close();
			cnx = null;
		}
	}

	public function isAvailable() : Bool {
		return cnx != null;
	}

	public function set( key:String, any:Dynamic, ?expiresSeconds:Int ) : Bool {
		if (cnx == null)
			return false;
		var data = serialize(any);
		var res = false;
		try res = cnx.set(key, neko.Lib.bytesReference(data), expiresSeconds) catch (e:Dynamic) cnx = null;
		return res;
	}

	public function get( key:String ) : Dynamic {
		if (cnx == null) return null;
		var res = null;
		try res = cnx.get(key) catch(e:Dynamic) cnx=null;
		if (res == null)
			return null;
		return unserialize(neko.Lib.stringReference(res.data));
	}

	public function add( key:String, any:Dynamic, ?expiresSeconds:Int ) : Bool {
		if (cnx == null) return false;
		var data = serialize(any);
		var res = false;
		try res = cnx.add(key, neko.Lib.bytesReference(data), expiresSeconds) catch (e:Dynamic) cnx = null;
		return res;
	}

	public function replace( key:String, any:Dynamic, ?expiresSeconds:Int ) : Bool {
		if (cnx == null) return false;
		var data = serialize(any);
		var res = false;
		try res = cnx.replace(key, neko.Lib.bytesReference(data), expiresSeconds) catch (e:Dynamic) cnx = null;
		return res;
	}

	public function delete( key:String, ?delay:Int ) : Bool {
		if (cnx == null) return false;
		var res = false;
		try res = cnx.delete(key, delay) catch (e:Dynamic) cnx = null;
		return res;
	}

	public function flushAll( ?delay:Int ) : Bool {
		if (cnx == null) return false;
		var res = false;
		try res = cnx.flushAll(delay) catch (e:Dynamic) cnx = null;
		return res;
	}
}
