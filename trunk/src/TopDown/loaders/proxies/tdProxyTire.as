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
	public class tdProxyTire extends qb2ProxyUserObject
	{
		[Inspectable(defaultValue="default", name="friction (default=1.5)")]
		public var _float_friction:String = "default";

		[Inspectable(defaultValue="default", name="rollingFriction (default=.01)")]
		public var _float_rollingFriction:String = "default";
		
		[Inspectable(defaultValue="default", name="Mass in kg (default=20)")]
		public var _float_mass:String = "default";
		
		[Inspectable(defaultValue="default",enumeration="default,true,false", name='canTurn (default=false)')]
		public var _bool_canTurn:String = "default";
		
		[Inspectable(defaultValue="default",enumeration="default,true,false", name='isDriven (default=false)')]
		public var _bool_isDriven:String = "default";
		
		[Inspectable(defaultValue="default",enumeration="default,true,false", name='canBrake (default=false)')]
		public var _bool_canBrake:String = "default";
		
		[Inspectable(defaultValue="default",enumeration="default,true,false", name='flippedTurning (default=false)')]
		public var _bool_flippedTurning:String = "default";
	}
}