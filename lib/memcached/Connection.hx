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

class Connection {

	private var socket : neko.net.Socket;

	/**
		Creates a new client connected to specified Memcached daemon.
	**/
	public function new( ?host:String, ?port:Int ){
		socket = new neko.net.Socket();
		if (host != null)
			connect(host, port);
	}

	/**
		Connect to memcached server.
	**/
	public function connect( host:String, port:Int ){
		socket.connect(new neko.net.Host(host), port);
	}

	/**
		Set socket timeout.
	**/
	public function setTimeout( timeout:Float ){
		socket.setTimeout(timeout);
	}

	/**
		Add a Memcached item.
		Returns true on success, false if item already exists or cannot be added.
	**/
	public function add( key:String, data:haxe.io.Bytes, ?expires:Int, ?flag:Int ) : Bool {
		command(["add", key, if(flag==null) 0 else flag, if(expires == null) 0 else expires, data.length]);
		writeData(data);
		return readLine() == "STORED";
	}
	
	/**
		Replace a Memcached item.
		Returns true on success, false if item does not exist or cannot be replaced.
	**/
	public function replace( key:String, data:haxe.io.Bytes, ?expires:Int, ?flag:Int ) : Bool {
		command(["replace", key, if(flag==null) 0 else flag, if(expires == null) 0 else expires, data.length]);
		writeData(data);
		return readLine() == "STORED";
	}

	/**
		Add or replace a Memcached item.
		Returns true on succes, false on error.
	**/
	public function set( key:String, data:haxe.io.Bytes, ?expires:Int, ?flag:Int ) : Bool {
		command(["set", key, if(flag==null) 0 else flag, if(expires == null) 0 else expires, data.length]);
		writeData(data);
		return readLine() == "STORED";
	}

	/**
		Retrieve a Memcached item.
		Returns Item on success, null if item does not exist.
	**/
	public function get( key:String ) : Item {
		command(["get",key]);
		var item = readData();
		while (item != null && readData() != null){}
		return item;
	}

	/**
		Remove an item from Memcached.
		Returns true on success, false if item does not exist.
	**/
	public function delete( key:String, ?time:Int ) : Bool {
		command(["delete", key, if (time != null) time]);
		return readLine() == "DELETED";
	}

	/**
		Empty Memcached.

		?time : seconds before real cleanup
	**/
	public function flushAll( ?time:Int ) : Bool {
		command(["flush_all", if (time != null) time]);
		return readLine() == "OK";
	}

	/**
		Retrieve Memcached statistics.
	**/
	public function stats( ?args:String ) : String {
		command(["stats", args]);
		return readLine();
	}

	/**
		Close client connection.
	**/
	public function close(){
		command(["quit"]);
		try socket.close() catch(e:Dynamic) {}
	}

	function command( args:Array<Dynamic> ){
		var cmd = new StringBuf();
		cmd.add(args.shift());
		for (i in args){
			if (i != null){
				cmd.add(" ");
				cmd.add(Std.string(i));
			}
		}
		cmd.add("\r\n");
		socket.output.writeString(cmd.toString());
	}

	function writeData( data:haxe.io.Bytes ){
		socket.output.writeBytes(data, 0, data.length);
		socket.output.writeString("\r\n");
	}

	function readLine() : String {
		var result = new StringBuf();
		var brline = false;
		do {
			var c = String.fromCharCode(socket.input.readByte());
			if (brline){
				if (c == "\n")	
					break;
				else {
					result.add("\r");
					result.add(c);
					brline = false;
				}
			}
			else if (c == "\r")
				brline = true;
			else
				result.add(c);
		}
		while (true);
		return result.toString();
	}

	function readData() : Item {
		var status = readLine();
		if (status == "END")
			return null;
		var parts = status.split(" ");
		if (parts[0] != "VALUE")
			return null;
		var size = Std.parseInt(parts[3]);
		var item = { key:parts[1], data:haxe.io.Bytes.alloc(size) };
		socket.input.readBytes(item.data, 0, size);
		socket.input.readByte();
		socket.input.readByte();
		return item;
	}
}
