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

package QuickB2.debugging.drawing
{
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2_debugDrawSettings
	{
		public static var flags:uint = qb2_debugDrawFlags.OUTLINES | qb2_debugDrawFlags.FILLS | qb2_debugDrawFlags.CIRCLE_SPOKES | qb2_debugDrawFlags.JOINTS;
		
		private static const DEFAULT_ALPHA:Number    = .75;
		
		public static var dynamicFillColor:uint      = 0x0000ff;
		public static var dynamicOutlineColor:uint   = 0xffffff;
		
		public static var staticFillColor:uint       = 0x666666;
		public static var staticOutlineColor:uint    = 0xffffff;
		
		public static var kinematicFillColor:uint    = 0xff0000;
		public static var kinematicOutlineColor:uint = 0xffffff;
		
		public static var jointFillColor:uint        = 0xff9900;
		public static var jointOutlineColor:uint     = 0xff9900;
		
		public static var fillAlpha:Number           = DEFAULT_ALPHA;
		public static var outlineAlpha:Number        = DEFAULT_ALPHA;
		
		public static var vertexColor:uint           = 0x000000;
		public static var vertexAlpha:Number         = DEFAULT_ALPHA;
		
		public static var positionColor:uint         = 0x000000;
		public static var positionAlpha:Number       = DEFAULT_ALPHA;
		
		public static var boundBoxColor:uint         = 0x006633;
		public static var boundBoxAlpha:Number       = DEFAULT_ALPHA;
		
		public static var boundCircleColor:uint      = 0x006633;
		public static var boundCircleAlpha:Number    = DEFAULT_ALPHA;
		
		public static var centroidColor:uint         = 0x00ffff;
		public static var centroidAlpha:Number       = DEFAULT_ALPHA;
		
		public static var lineThickness:Number       = 1.0;
		public static var pointRadius:Number         = 3.0;
		
		public static var boundBoxStartDepth:uint    = 1;
		public static var boundBoxEndDepth:uint      = 1;
		
		public static var boundCircleStartDepth:uint = 1;
		public static var boundCircleEndDepth:uint   = 1;
		
		public static var centroidStartDepth:uint    = 1;
		public static var centroidEndDepth:uint      = 1;
		
		public static var jointLineThickness:Number  = 2.0;
		
		public static var frictionPointColor:Number  = 0xff0000;
		public static var frictionPointAlpha:Number  = DEFAULT_ALPHA;
		
		public static var terrainFillColor:uint      = 0x006600;
		public static var tripSensorFillColor:uint   = 0x990099;
		public static var soundEmitterFillColor:uint = 0xFFFF66;
		public static var effectFieldFillColor:uint  = 0xFF6666;
	}
}