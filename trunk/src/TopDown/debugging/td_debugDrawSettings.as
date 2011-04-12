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

package TopDown.debugging 
{
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class td_debugDrawSettings
	{
		public static var flags:uint = td_debugDrawFlags.TIRES | td_debugDrawFlags.SKIDS | td_debugDrawFlags.TRACKS | td_debugDrawFlags.TRACK_TETHERS;
		
		public static var tireFillColor:uint    = 0x000000;
		public static var tireOutlineColor:uint = 0xffffff;
		public static var tireLoadColor:uint    = 0xff0000;
		
		public static var tireNumRotLines:uint  = 4;
		public static var tireLoadAlphaScale:Number = 20;
		public static var tireScale:Number = 1;
		public static var tiresOnTop:Boolean = true;
		
		public static var skidColor:uint  = 0x000000;
		
		public static var trackColor:uint = 0x999999;
		public static var trackThickness:Number = 1;
		public static var trackArrowSize:Number = 10;
		
		public static var tetherColor:uint = 0x00ff00;
		public static var tetherThickness:Number = 2;
		public static var tetherAlpha:Number = .5;
		
		public static var antennaColor:uint = 0xCC00FF;
	}
}