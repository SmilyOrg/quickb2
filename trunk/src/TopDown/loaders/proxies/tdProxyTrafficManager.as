/**
 * Copyright (c) 2010 Johnson Center for Simulation at Pine Technical College
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package TopDown.loaders.proxies
{
	import QuickB2.loaders.proxies.*;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdProxyTrafficManager extends qb2ProxyUserObject
	{
		[Inspectable(defaultValue="", name="cars (comma-delimited)")]
		public var cars1:String = "";
		
		[Inspectable(defaultValue="", name="cars (more)")]
		public var cars2:String = "";
		
		[Inspectable(defaultValue="", name="cars (still more?)")]
		public var cars3:String = "";
		
		[Inspectable(defaultValue=.3)]
		public var spawnChance:Number = .3;
		
		[Inspectable(defaultValue=5)]
		public var maxNumCars:uint = 5;
		
		[Inspectable(defaultValue=1, name="Spawn Interval (seconds)")]
		public var spawnInterval:Number = 1;
	}
}